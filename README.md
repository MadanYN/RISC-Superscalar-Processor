# RISC-Superscalar-Processor

The presented processor has the following properties
- 16-bit processor
- Two instruction fetch superscalar
- Seperate instruction and data memory each of size 128KB
-  2-bit biMode branch predictor with a global BHR of 8 bits
-  Reservation station of 64 entries in the dispatch stage
-  Rename Register File(RRF) of 64 entries
-  4 pipelines with one each of Arithmetic-Logic Unit(ALU), Branch, Load and Store
-  Store buffer to address speculative stores
-  A FIFO re-order buffer of 127 entries for completing and retiring the instructions

PS : The repository contains the complete design with completed port mapping and the design is behaviourally correct. The design is not synthesised and timing analysis is not performed 
