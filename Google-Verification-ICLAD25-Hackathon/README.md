# GenAI for Design Verification (Google)

## Goal

In this design verification challenge your goal is to build an agent that writes correct simulation testbenches based on the natural language RTL specification.

The information available to the agent:
- Natural language specification of a Verilog module
- 31 implementations of the module where only one is correct

Disclaimer: natural language descriptions are synthetically generated and may be incomplete. We believe they contain enough information to find the right implenentation, but do warn that this may not always be the case.

## Infrastructure setup

### SLM category: 
The prerequisites are iVerilog and OpenROAD-flow-scripts that should be available on your laptops. For SLM problems, you will not be evaluated on hidden testcases!

### LLM category:
Solving these problems requires the Docker image already available in your GCP VM instance. You can run the docker image as follows to create an environment that has OpenROAD-flow-scripts and iVerilog already installed:

```
docker run -it --rm \
  -v ~/iclad_hackathon:/workspace/iclad_hackathon \
  iclad_hackathon:latest bash
```

Inside the docker container, you will find this repository already cloned and available to you in 

```
/workspace/iclad_hackathon/ICLAD-Hackathon-2025/problem-categories
```


## Instructions

* Implement your AI agent in `generate_testbench` function in `test_harness/agent.py` file
    * Your agent needs to return a complete verilog testbench code in a single string (do not include the module implementation).
    * The agent needs to finish running within 5 minutes or a dummy testbench will be used instead.
* Modify `requirements.txt` to include necessary Python dependencies to run your agent.
* Generate testbenches by running:
```bash
python test_harness/generate_testbenches.py \
    --problems_folder="${PWD}/visible_problems"
```
* Check that your generated testbenches compile and run:
```bash
python test_harness/run_evaluation.py \
    --problems_folder="${PWD}/hidden_problems"
```
Note: the score produced will not be the final one as during competition you do not have access to the answers.

You are only allowed to modify `agent.py`, `requirements.txt` and create new testbenches for visible modules. You can assume that `iverilog` binary is available and can call it during your agent execution via `subprocess.run` (we recommend setting a timeout).

## Testbench requirements

- Testebench module name is assumed to be `tb`
- It outputs `$display("TESTS PASSED")` if the mutant passes the testbench. It is important to use the same text as it will be used to determine the resust of the test.
- It calls `$finish` in the end.

All testbenches will be simulated using `iverilog` so the subset of the language they use need to be supported by it. You can see all details in `test_harness/run_evaluation.py` script.

## Evaluation criteria

We use precision to evaluate agent's performance per module: it is 0 if the original module did not pass the generated test and it is 1/(Number of passing modules) otherwise. Each module is weighted proportionally to the $\sqrt(\text{NumLines})$.

There are 10 visible and 10 hidden problems, the final score is a sum of normalized weighted precisions per problem split. So the minimum is 0 and maximum is 2 (1 per problem set).

In case of ties, we'll be manually evaluating simplicity of the solution and generated testbenches.

## Instructions for scoring with answers available

* Run evaluation for previously generated testbenches for visible problems:
```bash
python test_harness/run_evaluation.py \
  --problems_folder="${PWD}/visible_problems" \
  --answers_folder="${PWD}/visible_problems_answers"
```
* Generate testbenches for hidden problems:
```bash
python test_harness/generate_testbenches.py \
  --problems_folder="${PWD}/hidden_problems"
```
* Run evaluation for hidden problems testbenches:
```bash
python test_harness/run_evaluation.py \
  --problems_folder="${PWD}/hidden_problems" \
  --answers_folder="${PWD}/hidden_problems_answers"
```

Compute the final score as a sum of normalized weighted precisions computed over visible and hidden problems.
