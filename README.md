# EX_STAGE

## Overview
The **EX_STAGE** module represents the Execution stage of a 5-stage pipelined RISC-V CPU. It performs all arithmetic and logic operations using an ALU and passes the results, flags, and control signals to the MEM stage. It registers all inputs and outputs to support stable pipeline progression, forwarding, and hazard detection in future extensions.

## Features
- Interfaces directly with the ALU for performing operations
- Supports all RISC-V ALU operations using funct3 and funct7
- Computes result and sets condition flags (Z, V, C, N)
*Note: Check the link to see how the flags are implemented.
https://github.com/NoridelHerron/ALU_with_testBenches_vhdl/blob/main/README.md*
- pass through register destination and control signal opcode for the next stage.
- Prepares data for the MEM stage through EX/MEM pipeline registers.

## Project Structure
**EX_STAGE**/
- images/
    - tcl.png
    - wave.png
- src/
    - EX_STAGE.vhd
    - adder_32bits.vhd
    - ALU_32bits.vhd
    - FullAdder.vhd
    - FullSubtractor.vhd
    - sub_32bits.vhd
- test_benches/
    - tb_EX_STAGE.vhd
- .gitignore/
- README.md/

## Testbench Strategy
The testbench uses randomized testing to evaluate all supported ALU operations over 5000 input cases. It:
- Randomly generates inputs for operands A and B, funct3, and funct7
- Calculates expected output in software and compares it with hardware ALU output
- Validates instruction passthrough and control signal propagation.
- Tracks test statistics including per-operation failure counts and signal mismatches
- Provides clear feedback through the Tcl Console for debugging.

## Key Learnings
- Gained hands-on experience designing and testing a pipelined CPU execution stage
- Improved understanding of condition flag handling and ALU operation decoding
- Reinforced the importance of modular design for future extensions (hazard detection, forwarding, etc.)
- Learned the importance of passing the signal through each stage to maintain the pipeline integrity.

## Simulation Results
### Tcl Console Output
![Tcl Output – 5000 Cases](images/tcl.png)  
*5000 randomized tests passed.*
### Waveform Example
![Waveform Example](images/wave.png)   
*Successful pass through, where rd_in = rd_out and op_in = op_out.*

## How to Run
1. Launch **Vivado 2019** or newer
2. Open the project or create a new one and add the src and a test bench file.
3.  Set `tb_EX_STAGE.vhd` as the top-level simulation unit.
4. Run the simulation:
    - Go to Flow → Run Simulation → Run Behavioral Simulation
    - Or use the project manager's simulation shortcut.
    - Increase the simulation runtime if needed to capture full behavior.
5. View signals in the Waveform Viewer and test status in the Tcl Console.

## Author
**Noridel Herron** (@MIZZOU)  
Senior in Computer Engineering  
noridel.herron@gmail.com

## Contributing
This is a personal academic project. Suggestions, issues, and improvements are welcome through GitHub.

## License
MIT License

## Disclaimer
This project is developed solely for educational and personal learning purposes.  
It may contain unfinished or experimental features and is not intended for commercial or production use.
