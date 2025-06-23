#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

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

    # Define the file paths we expect to find
    testbench_file="tb.v"
    
    # Find the first available mutant file in the current directory
    mutant_file=$(find . -maxdepth 1 -name "mutant_*.v" | head -n 1)

    # Check if the required files exist before trying to run
    if [ ! -f "$testbench_file" ]; then
      echo "WARNING: 'tb.v' not found in '$problem_name'. Skipping."
      cd ../.. # Go back to the root before continuing
      continue
    fi

    if [ -z "$mutant_file" ]; then
      echo "WARNING: No 'mutant_*.v' files found in '$problem_name'. Skipping."
      cd ../.. # Go back to the root before continuing
      continue
    fi
    
    # Define the output file for the compiled simulation
    simulation_output_file="simulation_run"

    # CORRECTED LINE: Removed the extra dot before $mutant_file
    # The find command already returns a relative path like './mutant_1.v'
    full_command="iverilog -g2012 -o $simulation_output_file -s tb $testbench_file $mutant_file && vvp $simulation_output_file"

    echo "Running test against: $mutant_file"
    echo "Executing command: $full_command"
    echo "--- Simulation Output ---"
    
    # Execute the command
    eval "$full_command"
    
    echo "-------------------------"

    # Navigate back to the parent directory for the next loop
    cd ../..
  fi
done

echo ""
echo "All problems processed."


