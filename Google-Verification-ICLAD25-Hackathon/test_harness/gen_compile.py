# local_agent_harness.py (Full updated script)
import os
import subprocess
import glob
import agent # Your agent.py file
import constants

# MODIFIED run_single_test to return the error message
def run_single_test(testbench_path: str, dut_path: str) -> tuple[bool, str]:
    """
    Runs a single test of a testbench against a DUT using iverilog.
    Returns a tuple: (did_it_pass_the_test, compiler_error_message_or_test_output)
    A True status in the first element only happens if the test runs AND finds the SUCCESS message.
    """
    # print(f"\n--- Running test: tb.v vs {os.path.basename(dut_path)} ---") # Reduced verbosity
    output_dir = "/tmp/sim_output"
    os.makedirs(output_dir, exist_ok=True)
    compiled_sim_path = os.path.join(output_dir, "sim.out")

    compile_command = ['iverilog', '-g2012', '-o', compiled_sim_path, '-s', 'tb', testbench_path, dut_path]
    
    try:
        subprocess.run(compile_command, check=True, capture_output=True, text=True, timeout=30)
    except Exception as e:
        error_output = f"Iverilog compilation failed.\nCommand: {' '.join(e.cmd)}\nError:\n{e.stderr}"
        return False, error_output

    try:
        result = subprocess.run(['vvp', compiled_sim_path], check=True, capture_output=True, text=True, timeout=30)
        simulation_output = result.stdout
    except Exception as e:
        simulation_output = e.stdout + e.stderr
    
    if "SUCCESS: All test cases passed!" in simulation_output:
        return True, ""
    else:
        return False, f"Testbench ran but did not find 'SUCCESS'. Output:\n{simulation_output}"


# Main orchestration function with the new self-correction loop
def run_agent_on_problem(problem_folder: str):
    MAX_ATTEMPTS = 3 # Let's try to fix the code up to 2 times
    
    # --- Part 1: Initial Setup ---
    files_dict = {}
    verilog_files = glob.glob(os.path.join(problem_folder, '*.v'))
    spec_files = glob.glob(os.path.join(problem_folder, '*.md')) + glob.glob(os.path.join(problem_folder, '*.txt'))
    if not spec_files:
        print(f"ERROR: No spec file in {problem_folder}"); return
    for file_path in verilog_files + spec_files:
        with open(file_path, 'r') as f:
            files_dict[os.path.basename(file_path)] = f.read()

    print(f"\n{'='*60}\nRunning Self-Correcting Agent on: {problem_folder}\n{'='*60}")

    generated_tb_code = ""
    compiler_error = ""
    spec_text = files_dict[os.path.basename(spec_files[0])]
    dut_context = files_dict[os.path.basename(verilog_files[0])]

    # --- Part 2: The Generate-Debug-Regenerate Loop ---
    for attempt in range(1, MAX_ATTEMPTS + 1):
        print(f"\n--- AGENT ATTEMPT {attempt} ---")
        
        if attempt == 1:
            # First attempt: Use the standard prompt
            print("  - Generating initial testbench from specification...")
            generated_tb_code = agent.generate_testbench_with_gemini(spec_text, dut_context)
        else:
            # Subsequent attempts: Use the debugging prompt
            print("  - Attempting to fix code based on compiler error...")
            # This is the "packaged prompt" you asked for
            debugging_prompt = f"""
            You are a Verilog debugging expert. Your previous attempt to generate a testbench resulted in a compiler error.
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

            **Iverilog Compiler Error:**
            ---
            {compiler_error}
            ---

            Analyze the error message and the code, and provide a corrected, complete Verilog testbench.
            Remember, the top-level module MUST be named `tb`.
            Provide ONLY the pure, fixed Verilog code in your response.
            """
            generated_tb_code = agent.generate_testbench_with_gemini(debugging_prompt) 
        
        if not generated_tb_code:
            print("  - Agent failed to generate code. Halting.")
            break
            
        # Write the newly generated code to tb.v
        testbench_path = os.path.join(problem_folder, constants.TESTBENCH_FILE_NAME)
        with open(testbench_path, 'w') as f:
            f.write(generated_tb_code)
            
        # Test the new tb.v against ONE of the mutants to check for compilation errors.
        # We use a known-good reference file if it exists, otherwise just the first mutant.
        ref_file = next((f for f in verilog_files if "reference" in f), verilog_files[0])
        
        compilation_passed, error_message = run_single_test(testbench_path, ref_file)

        if "Iverilog compilation failed" not in error_message:
            print("  - [+] Code compiled successfully! Proceeding to full evaluation.")
            break # Exit the loop on successful compilation
        else:
            print(f"  - [-] Compilation failed on attempt {attempt}.")
            compiler_error = error_message # Save the error for the next loop iteration
            if attempt == MAX_ATTEMPTS:
                print("  - Max attempts reached. Halting.")

    # --- Part 3: Final Evaluation (runs only if compilation eventually succeeded) ---
    print(f"\n--- FINAL EVALUATION for {os.path.basename(problem_folder)} ---")
    results = {}
    for dut_path in verilog_files:
        is_passing, _ = run_single_test(testbench_path, dut_path)
        results[os.path.basename(dut_path)] = "PASSED" if is_passing else "FAILED"
        
    passing_count = sum(1 for res in results.values() if res == "PASSED")
    for dut, result in results.items():
        print(f"  - {dut}: {result}")

    print(f"\nPrecision Score Estimate: 1 / {passing_count if passing_count > 0 else 'inf'}")
    print(f"{'='*60}")


# A new helper function might be needed in agent.py to handle generic prompts
# In agent.py, add:
# def generate_testbench_from_prompt(prompt: str) -> str:
#     model = genai.GenerativeModel('gemini-1.5-pro-latest')
#     response = model.generate_content(prompt)
#     # ... (cleaning logic) ...
#     return cleaned_code

# --- Main Execution ---
if __name__ == "__main__":
    problem_to_test = "visible_problems/counter" 
    if not os.path.isdir(problem_to_test):
         print(f"ERROR: Problem folder '{problem_to_test}' not found.")
    else:
        run_agent_on_problem(problem_to_test)
