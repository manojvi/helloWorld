"""Agent definition that generates a testbench."""

import constants
from vertexai.preview.generative_models import GenerativeModel
import vertexai
import os
import argparse
import glob
from typing import Optional


# --- Helper functions adapted for dictionary input ---





def find_specification_file(problems_folder):
    """Finds the natural language specification file."""
    for ext in ['*.txt', '*.md']:
        files = glob.glob(os.path.join(problems_folder, ext))
        if files:
            return files[0]
    return None

def find_verilog_modules(problems_folder):
    """Finds all Verilog module files."""
    return glob.glob(os.path.join(problems_folder, '*.v'))


# TODO: Implement this.
def generate_testbench(file_name_to_content: dict[str, str]) -> str:
    del file_name_to_content
    print(f" Hello from generate: file_name_to_content")
    # 1. Find the input files
    spec_file = find_specification_file(file_name_to_content)
    verilog_files = find_verilog_modules(file_name_to_content)

    if not spec_file:
        print("Error: Specification file not found.")
        return
    if not verilog_files:
        print("Error: No Verilog modules found.")
        return

    print(f"  - Specification: {os.path.basename(spec_file)}")
    print(f"  - Found {len(verilog_files)} Verilog modules.")

    # ... (Agent logic will go here) ...

    return constants.DUMMY_TESTBENCH
def find_specification_file(file_name_to_content: dict[str, str]) -> Optional[str]:
    """
    Finds the specification file name from the dictionary keys.
    The spec is typically a .txt or .md file.
    """
    for file_name in file_name_to_content.keys():
        if file_name.endswith('.txt') or file_name.endswith('.md'):
            return file_name
    return None

def find_verilog_modules(file_name_to_content: dict[str, str]) -> list[str]:
    """Finds all Verilog module file names from the dictionary keys."""
    return [name for name in file_name_to_content.keys() if name.endswith('.v')]


# --- Gemini API Interaction ---

def generate_testbench_with_gemini(specification_text: str, dut_content: Optional[str] = None) -> str:
    """
    Uses the Gemini API to generate a Verilog testbench.
    
    Args:
        specification_text: The natural language specification of the DUT.
        dut_content: Optional. The content of one of the DUT modules for more context.

    Returns:
        The generated Verilog testbench code as a string, or an empty string on failure.
    """
    # Best practice: Use an environment variable for your API key
    # Ensure this is set in your execution environment.
    # For local testing:
    # from dotenv import load_dotenv
    # load_dotenv()
    # genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
    # In the hackathon environment, this might be pre-configured.
    vertexai.init(location="us-central1")
	#model = genai.GenerativeModel('gemini-1.5-pro-latest')
    model = GenerativeModel("gemini-2.5-pro")
    response = model.generate_content("Say hi from inside the OpenROAD container!")
    print(response.candidates[0].text)


    # --- The Prompt is the most critical part ---
    # Providing one of the DUTs as context helps the model understand the port names and widths correctly.
    dut_context_prompt = ""
    if dut_content:
        dut_context_prompt = f"""
        Here is an example implementation of the module to help you understand the exact port names, types, and parameters.

        **Verilog DUT Example:**
        ---
        ```verilog
        {dut_content}
        ```
        ---
        """

    prompt = f"""
    You are an expert Verilog Verification Engineer. Your task is to create a high-quality,
    self-checking Verilog testbench from the provided natural language specification.

    **Requirements for the Testbench:**
	1.  The top-level testbench module **MUST be named `tb`**. This is a strict requirement.
    1.  **Self-Checking:** The testbench must contain logic to automatically verify the DUT's
        outputs against expected values for each test case.
    2.  **Clear Assertions:** On any failure, it must print a descriptive error message
        indicating the inputs, actual outputs, and expected outputs, then terminate.
    3.  **Success Message:** If all tests pass, it must print a clear success message
        at the end of the simulation, such as "SUCCESS: All test cases passed!".
    4.  **Thoroughness:** Generate a comprehensive set of test vectors that cover edge cases
        mentioned or implied in the specification (e.g., zero values, max values, overflow,
        carry flags, etc.).
    5.  **Clean Output:** Provide ONLY the pure Verilog code for the testbench, with no
        surrounding text, explanations, or markdown formatting.

    **Natural Language Specification:**
    ---
    {specification_text}
    ---
    {dut_context_prompt}
    Now, generate the Verilog testbench code. The module under test will be instantiated,
    so you do not need to know its exact filename, just its module name from the spec.
    """

    try:
        print("  - Generating testbench with Gemini...")
        response = model.generate_content(prompt)
        
        # Clean the response to ensure it's pure Verilog code
        verilog_code = response.text.strip()
        if verilog_code.startswith("```verilog"):
            verilog_code = verilog_code[len("```verilog"):].strip()
        if verilog_code.endswith("```"):
            verilog_code = verilog_code[:-len("```")].strip()
            
        return verilog_code
    except Exception as e:
        print(f"An error occurred with the Gemini API: {e}")
        return ""

# --- Main agent function to be implemented ---

def generate_testbench(file_name_to_content: dict[str, str]) -> str:
    """
    The main function for the agent. It takes a dictionary of file names to their
    content and returns a string containing the generated testbench.
    """
    print("--- Running Agent ---")
    
    # 1. Find the specification file name from the dictionary keys
    spec_filename = find_specification_file(file_name_to_content)
    if not spec_filename:
        print("Error: Specification file (.txt or .md) not found in the input dictionary.")
        return constants.DUMMY_TESTBENCH

    # 2. Find all Verilog modules
    verilog_files = find_verilog_modules(file_name_to_content)
    if not verilog_files:
        print("Error: No Verilog modules (.v) found in the input dictionary.")
        return constants.DUMMY_TESTBENCH

    print(f"  - Specification identified: {spec_filename}")
    print(f"  - Found {len(verilog_files)} Verilog modules.")

    # 3. Extract the content of the specification and one of the DUTs
    specification_text = file_name_to_content[spec_filename]
    # Provide one DUT's content for better context in the prompt
    dut_context_content = file_name_to_content[verilog_files[0]] 

    # 4. Generate the testbench using the Gemini API
    testbench_code = generate_testbench_with_gemini(specification_text, dut_context_content)

    # 5. Return the generated code or the dummy testbench on failure
    if testbench_code:
        print("  - Testbench generated successfully.")
        return testbench_code
    else:
        print("  - Failed to generate testbench from API, returning dummy testbench.")
        return constants.DUMMY_TESTBENCH
