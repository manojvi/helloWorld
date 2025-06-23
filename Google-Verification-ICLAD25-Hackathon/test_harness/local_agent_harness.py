# local_test_harness.py
# import os
# import agent # Your agent.py file
# import constants
# 
# def run_agent_on_problem(problem_folder):
#     files_dict = {}
#     for file_name in os.listdir(problem_folder):
#         file_path = os.path.join(problem_folder, file_name)
#         if os.path.isfile(file_path):
#             with open(file_path, 'r') as f:
#                 files_dict[file_name] = f.read()
# 
#     print(f"\n--- Testing agent on: {problem_folder} ---")
#     generated_tb = agent.generate_testbench(files_dict)
# 
#     if generated_tb == constants.DUMMY_TESTBENCH:
#         print("Agent returned the DUMMY testbench.")
#     else:
#         print("\n--- Agent returned a generated testbench: ---")
#         print(generated_tb)
#         testbench_file = "visible_problems/ecc_sed_encoder/tb.v"
#         testbench_file.write_text(generated_tb)
#         print("------------------------------------------")
# 
# Assuming you have a folder structure like 'problems/adder'
# run_agent_on_problem('visible_problems/ecc_sed_encoder')

# local_agent_harness.py
import os
import subprocess
import glob
import agent # Your agent.py file
import constants

def run_single_test(testbench_path: str, dut_path: str) -> bool:
    """
    Runs a single test of a testbench against a DUT using iverilog.
    This function mimics the core logic of the run_evaluation.py script.

    Args:
        testbench_path: The path to the tb.v file.
        dut_path: The path to the specific mutant .v file to test against.

    Returns:
        True if the simulation runs and finds "SUCCESS", False otherwise.
    """
    print(f"\n--- Running test: tb.v vs {os.path.basename(dut_path)} ---")
    
    # Define the output path for the compiled simulation
    # Placing it in a temp directory is good practice
    output_dir = "/tmp/sim_output"
    os.makedirs(output_dir, exist_ok=True)
    compiled_sim_path = os.path.join(output_dir, "sim.out")

    # 1. Compile the Verilog files
    compile_command = [
        'iverilog',
        '-g2012',  # Use the same flag as the official script
        '-o', compiled_sim_path,
        '-s', 'tb', # Specify 'tb' as the top-level module
        testbench_path,
        dut_path
    ]
    
    try:
        # Use capture_output=True to hide compiler warnings unless there's an error
        subprocess.run(compile_command, check=True, capture_output=True, text=True, timeout=30)
        print(f"  [+] Compilation SUCCESS")
    except FileNotFoundError:
        print("  [-] ERROR: `iverilog` not found. Is Icarus Verilog installed and in your PATH?")
        return False
    except subprocess.TimeoutExpired:
        print("  [-] ERROR: Compilation timed out.")
        return False
    except subprocess.CalledProcessError as e:
        print(f"  [-] ERROR: Compilation FAILED. Return code: {e.returncode}")
        print(f"      Compiler output:\n{e.stderr}")
        return False

    # 2. Run the compiled simulation
    try:
        result = subprocess.run(['vvp', compiled_sim_path], check=True, capture_output=True, text=True, timeout=30)
        simulation_output = result.stdout
        print("  [+] Simulation ran to completion.")
    except subprocess.TimeoutExpired:
        print("  [-] ERROR: Simulation timed out. (This is good if the DUT has an infinite loop!)")
        return False # A timeout is a valid way to fail a mutant
    except subprocess.CalledProcessError as e:
        # A non-zero exit can be a valid failure, we still check the output
        simulation_output = e.stdout + e.stderr
        print("  [!] Simulation finished with a non-zero exit code (might be a test failure).")

    # 3. Check the output for the success message
    if "SUCCESS: All test cases passed!" in simulation_output:
        print("  --> RESULT: PASSED (Found 'SUCCESS' message)")
        return True
    else:
        print("  --> RESULT: FAILED (No 'SUCCESS' message found)")
        return False


def run_agent_on_problem(problem_folder: str):
    """
    Orchestrates generating a testbench and running it against all mutants.
    """
    # --- Part 1: Generate the Testbench (same as before) ---
    files_dict = {}
    verilog_files = glob.glob(os.path.join(problem_folder, '*.v'))
    
    spec_files = glob.glob(os.path.join(problem_folder, '*.md')) + \
                 glob.glob(os.path.join(problem_folder, '*.txt'))

    if not spec_files:
        print(f"ERROR: No specification file found in {problem_folder}")
        return

    # Create the dictionary for the agent
    for file_path in verilog_files + spec_files:
        with open(file_path, 'r') as f:
            files_dict[os.path.basename(file_path)] = f.read()

    print(f"\n{'='*60}\nTesting agent on: {problem_folder}\n{'='*60}")
    generated_tb_code = agent.generate_testbench(files_dict)
    
    testbench_path = os.path.join(problem_folder, constants.TESTBENCH_FILE_NAME) # "tb.v"
    with open(testbench_path, 'w') as f:
        f.write(generated_tb_code)
        
    if generated_tb_code == constants.DUMMY_TESTBENCH:
        print("Agent returned the DUMMY testbench. Halting tests for this problem.")
        return
    else:
        print(f"Agent generated new testbench: {testbench_path}")

    # --- Part 2: Run Evaluation against all Verilog files in the folder ---
    print(f"\n--- Starting Evaluation for {os.path.basename(problem_folder)} ---")
    results = {}
    for dut_path in verilog_files:
        is_passing = run_single_test(testbench_path, dut_path)
        results[os.path.basename(dut_path)] = "PASSED" if is_passing else "FAILED"
        
    # --- Part 3: Print Summary ---
    print(f"\n--- SUMMARY for {os.path.basename(problem_folder)} ---")
    passing_count = 0
    for dut, result in results.items():
        if result == "PASSED":
            passing_count += 1
        print(f"  - {dut}: {result}")

    print(f"\nPrecision Score Estimate: 1 / {passing_count}")
    print(f"Goal: Achieve a score of 1 / 1 (only the reference module should pass).")
    print(f"{'='*60}")


# --- Main Execution ---
if __name__ == "__main__":
    # To run, specify the problem folder you want to test, e.g., "visible_problems/counter"
    # Or leave it empty to prompt you.
    problem_to_test = "visible_problems/fifo_flops" # <-- CHANGE THIS to the problem you're working on

    if not problem_to_test or not os.path.isdir(problem_to_test):
         print(f"ERROR: Problem folder '{problem_to_test}' not found.")
         print("Please edit the `problem_to_test` variable in the script.")
    else:
        run_agent_on_problem(problem_to_test)
