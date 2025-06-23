#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# We remove this because we expect iverilog/vvp to fail for mutants.
# set -e

# --- Configuration ---
# The parent directory containing all the individual problem folders.
PROBLEMS_PARENT_DIR="visible_problems"

# --- Main Script Logic ---

# Check if the parent directory exists
if [ ! -d "$PROBLEMS_PARENT_DIR" ]; then
  echo "Error: Directory '$PROBLEMS_PARENT_DIR' not found."
  echo "Please run this script from the correct location."
  exit 1
fi

echo "Starting evaluation for all problems in '$PROBLEMS_PARENT_DIR'..."

# Loop through each subdirectory in the parent directory
for problem_dir in "$PROBLEMS_PARENT_DIR"/*/; do
  # Check if it's actually a directory
  if [ -d "$problem_dir" ]; then
    
    # Get the base name of the directory for logging
    problem_name=$(basename "$problem_dir")
    echo ""
    echo "============================================================"
    echo "--- Processing problem: $problem_name"
    echo "============================================================"

    # Navigate into the problem directory
    cd "$problem_dir"

    testbench_file="tb.v"
    
    # Check if the testbench file exists before trying to run
    if [ ! -f "$testbench_file" ]; then
      echo "WARNING: 'tb.v' not found in '$problem_name'. Skipping."
      cd ../.. # Go back to the root before continuing
      continue
    fi

    # Create a directory for logs, clearing old ones
    rm -rf logs
    mkdir -p logs

    passing_files=()

    # Find all Verilog files (mutants only) to test against
    verilog_files=$(find . -maxdepth 1 -name "mutant_*.v")
    
    if [ -z "$verilog_files" ]; then
        echo "WARNING: No 'mutant_*.v' files found. Skipping."
        cd ../..
        continue
    fi

    for dut_file in $verilog_files; do
        dut_basename=$(basename "$dut_file")
        echo -n "  - Testing against $dut_basename..."

        simulation_output_file="simulation_run"
        log_file="logs/${dut_basename}.log"

        # Compile and run, redirecting all output (stdout and stderr) to the log file
        # The '|| true' prevents the script from exiting if a command fails (which is expected for most mutants)
        { iverilog -g2012 -o $simulation_output_file -s tb $testbench_file $dut_file && vvp $simulation_output_file; } > "$log_file" 2>&1 || true

        # Check the log file for the success message
        if grep -q "SUCCESS: All test cases passed!" "$log_file"; then
            echo " [PASS]"
            passing_files+=("$dut_basename")
        else
            echo " [FAIL]"
        fi
    done

    # --- Final Summary for the Problem ---
    echo ""
    echo "--- Summary for $problem_name ---"
    if [ ${#passing_files[@]} -eq 1 ]; then
        echo "✅ SUCCESS: Exactly one module passed as expected."
        echo "   Passing file: ${passing_files[0]}"
    elif [ ${#passing_files[@]} -eq 0 ]; then
        echo "❌ ERROR: No modules passed. The testbench may have a logic error."
    else
        echo "❌ WARNING: Multiple modules passed. The testbench is not selective enough."
        echo "   Passing files: ${passing_files[*]}"
    fi

    # Navigate back to the parent directory for the next loop
    cd ../..
  fi
done

echo ""
echo "All problems processed."


