# agent.py
import os
import subprocess
import tempfile
from typing import Optional
from vertexai.preview.generative_models import GenerativeModel
import vertexai

# This will be provided by the hackathon environment
import constants

# ==============================================================================
# === INTERNAL HELPER FUNCTIONS (Previously in the test harness) =============
# ==============================================================================

def _compile_testbench(testbench_path: str, dut_path: str, iverilog_path: str = "iverilog") -> tuple[bool, str]:
    """
    Private helper to compile a testbench against a DUT using iverilog.
    Returns a tuple: (compilation_success: bool, error_message: str).
    """
    compiled_sim_path = os.path.join(tempfile.gettempdir(), "sim.out")
    compile_command = [
        iverilog_path, '-g2012', '-o', compiled_sim_path, '-s', 'tb',
        testbench_path, dut_path
    ]
    try:
        subprocess.run(compile_command, check=True, capture_output=True, text=True, timeout=30)
        return True, ""
    except Exception as e:
        error_output = f"Iverilog compilation failed.\nCommand: {' '.join(getattr(e, 'cmd', ''))}\nError:\n{getattr(e, 'stderr', str(e))}"
        return False, error_output

def _find_file_with_suffix(file_name_to_content: dict[str, str], suffixes: list[str]) -> Optional[str]:
    """Finds the first file name in the dictionary that matches a list of suffixes."""
    for file_name in file_name_to_content:
        if any(file_name.endswith(suffix) for suffix in suffixes):
            return file_name
    return None

def _generate_code_from_gemini(prompt: str) -> str:
    """A single, generic function to call the Gemini API."""
    vertexai.init(location="us-central1")
	#model = genai.GenerativeModel('gemini-1.5-pro-latest')
    model = GenerativeModel("gemini-2.5-pro")
    #model = GenerativeModel("gemini-2.0-flash-001")
    response = model.generate_content("Say hi from inside the OpenROAD container!")
    print(response.candidates[0].text)

    try:
        response = model.generate_content(prompt) # Set a generous timeout
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


# ==============================================================================
# === MAIN AGENT ENTRY POINT ===================================================
# ==============================================================================

def generate_testbench(file_name_to_content: dict[str, str]) -> str:
    """
    The main agent function called by the hackathon driver.
    It generates a testbench and uses an internal iterative loop to fix
    compilation errors until the testbench is valid.
    """
    MAX_ATTEMPTS = 5  # Set a limit to avoid infinite loops and timeouts
    print("--- Running Self-Correcting Agent ---")

    # --- 1. Initial Setup: Extract files from the input dictionary ---
    spec_filename = _find_file_with_suffix(file_name_to_content, ['.md', '.txt'])
    if not spec_filename:
        print("ERROR: Specification file not found in input.")
        return constants.DUMMY_TESTBENCH

    verilog_filenames = [name for name in file_name_to_content if name.endswith('.v')]
    if not verilog_filenames:
        print("ERROR: No Verilog modules found in input.")
        return constants.DUMMY_TESTBENCH

    spec_text = file_name_to_content[spec_filename]
    # Use 'reference.v' for context if it exists, otherwise the first mutant
    ref_filename = next((f for f in verilog_filenames if "reference.v" in f), verilog_filenames[0])
    dut_context_text = file_name_to_content[ref_filename]

    generated_tb_code = ""
    compiler_error = ""

    # --- 2. The Iterative Compile-Debug-Recompile Loop ---
    for attempt in range(1, MAX_ATTEMPTS + 1):
        print(f"  - Code Generation Attempt {attempt} of {MAX_ATTEMPTS}...")

        if attempt == 1:
            # First attempt: Create the initial prompt
            prompt = f"""
            You are an world class expert Verilog Verification Engineer. Your task is to create a high-quality,
            self-checking Verilog testbench from the provided natural language specification.

            **Requirements for the Testbench:**
            1.  The top-level testbench module **MUST be named `tb`**.
            2.  It must be **self-checking** with clear PASS/FAIL messages for each test.
            3.  If all tests pass, it must print a final, unique success message: "SUCCESS: All test cases passed!".
            4.  Cover edge cases implied by the specification.
            5.  Ensure all internal 'expected' value variables are correctly initialized before being used in a comparison.
            6.  Provide ONLY the pure Verilog code as your output.

            **Natural Language Specification:**
            ---
            {spec_text}
            ---

            **Example DUT Implementation (for port reference):**
            ---
            ```verilog
            {dut_context_text}
            ```
            ---
            Generate the Verilog testbench now.
            """
        else:
            # Subsequent attempts: Create the debugging prompt
            prompt = f"""
            You are a meticulous and senior Verilog Verification Engineer tasked with creating a robust, self-checking testbench.
            Your goal is to create a testbench that is both syntactically perfect and logically rigorous enough to find subtle bugs in various implementations of a design.
            You are a Verilog debugging expert. Your previous attempt to generate a testbench resulted in a compilation error.
            Your task is to fix the broken Verilog code.

            **Original Specification:**
            ---
            {spec_text}
            ---

            **Broken Verilog Code (Previous Attempt):**
            ---
            ```verilog
            {generated_tb_code}
            ```
            ---

            **Iverilog Compiler Error Message:**
            ---
            {compiler_error}
            ---

            Analyze the error message and the code, and provide the full, corrected Verilog testbench.
            Ensure the top-level module is named `tb`. Do not add any explanations, just the code.
            """

        generated_tb_code = _generate_code_from_gemini(prompt)

        if not generated_tb_code:
            print("  - Agent failed to receive a response from the API. Returning dummy testbench.")
            return constants.DUMMY_TESTBENCH

        # --- 3. Internal Compilation Check using Temporary Files ---
        try:
            # Create temporary files to pass to the iverilog subprocess
            with tempfile.NamedTemporaryFile(mode='w+', suffix='.v', delete=True, dir='.') as tb_file, \
                 tempfile.NamedTemporaryFile(mode='w+', suffix='.v', delete=True, dir='.') as dut_file:

                tb_file.write(generated_tb_code)
                tb_file.flush() # Ensure content is written to disk

                dut_file.write(dut_context_text)
                dut_file.flush() # Ensure content is written to disk

                print(f"  - Compiling generated code...{dut_file.name}")
                is_compilable, error_message = _compile_testbench(tb_file.name, dut_file.name)

                if is_compilable:
                    print("  - [+] SUCCESS: Testbench {dut_file.name} is compilation-ready!")
                    # The code is good, return it to the main driver.
                    return generated_tb_code
                else:
                    print(f"  - [-] FAILURE: Compilation failed on attempt {attempt}.")
                    compiler_error = error_message # Save error for the next attempt
        except Exception as e:
            print(f"An error occurred during the temporary file compilation check: {e}")
            compiler_error = str(e) # Pass the exception as an error to the LLM

    # --- 4. Final Fallback ---
    print(f"--- Agent failed to produce a compilable testbench after {MAX_ATTEMPTS} attempts. ---")
    # If the loop finishes without success, return the last generated (but broken) code
    # or the dummy testbench, as per the hackathon rules.
    return generated_tb_code or constants.DUMMY_TESTBENCH
