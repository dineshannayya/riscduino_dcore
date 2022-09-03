####################
# Thsi file document the feature addition and status

- 28th Aug 2022 - Dinesh A
    A. Create 10 system strap pick following pads and generate pad direction control and master reset
         sflash_sck, sflash_ss0,sflash_ss1,sflash_ss2,sflash_ss3,
         sflash_io0,sflash_io1,sflash_io2,sflash_io3,dbg_clk_mon
    B. uart master config control thrugh strap and remove dependency with caravel la_data_in
       - baud rate control based on strap
    C. Enable default reset enable for wishbone, qspi slave on power up (with delayed reset after strap loading)
    D. Give option for Auto riscv core[0] removal based on strap
    E. Default system clock selection based on strap
       - wb clock or xtal pin
    F. wbs and riscv, usb clock selection based on strap
    G. strap to control the boot up configuration qspi-flash/sram
    I. Riscv cache on/bypass through strap
    J. Riscv SRAM edge selection through strap
    K. Add Strap sticky bit for software based reboot
    M. Created Master Reset control block to manage the boot sequence
        A. Power On
            - Power Up wait cycle  minimum 50 ms (Add fast boot with strap)
            - Strap latch control
            - Pad Direction control
            - core reset control
        B,software reset request
            - core reset control
           
  
- 2 Sept 2022 - Dinesh A
     QSPI Design Changes
         Test case:
             Add QSPI test case to validate parallel Direct and Indirect access
         Design Change:
             A. Add previous power on strap from SRAM flash to take care of mode switching
                1. If the current & previous sram strap is Single, then bypass mode switching
                2. If the current=Single and Previous: Quad, then switch mode by command 0xFF (RSTDQI)
                3. If the current=Quad and Previous: Quad, then bypass mode switching
                4. If the current=Quad and Previous: Single, then switch mode by command 0x38 (ESQI)
                Note: Power On Always assume previous strap = Single 
