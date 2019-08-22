

# DepthMap generation on FPGA


Most of the image processing projects in the academia has been done on higher end FPGA's with considerable amount of resources. The main objective of this project is to implement a reliable embedded system on a lower end FPGA with limitted resources. This project is based on Disparity calculation based on SAD (Sum of Absolute Difference) algorithm and creating a depth map.

Hardware used for this project

 - Basys 3 FPGA board
 - 2x OV7670 image sensor modules

This project has 3 major sections

 1. [Functional verification of disparity generator based on Verilog](https://github.com/Archfx/FPGA_depthMap)
 2. [Stereo camera implementation using OV7670 sensors based on VHDL](https://github.com/Archfx/FPGA-stereo-Camera-Basys3)
 3. [Real time disparity generation on Basys3 FPGA](https://github.com/Archfx/FPGA-DepthMap-Basys3)

## Functional verification
Hardware description languages(HDL) are not meant to be for rapid prototyping. Therefore in this case I have used python as the prototyping tool. SAD algorithm was implemented on python from scratch without using any external library. I refrained from using 2D image arrays to store data because then the HDL implementation is straight forward.

**SAD theory** 
Sum of Absolute difference is based on a simple geomatric concept. Where it use the stereo vision to calculate the distance to the objects. For the ipmplementaion two cameras should be in same plane and they should not have any vertical offsets in their alignments.

**Python implementation**

The python implementation can be found [here](https://github.com/Archfx/FPGA_depthMap/blob/master/Python_test_implementation/Disparity_Python_implementation_scratch.ipynb)

Test images used
For the functional verification I have used most famous stereo image pair "TSukuba" stereo pair
| Tsukuba left image | ![Tsukuba left](https://github.com/Archfx/FPGA_depthMap/blob/master/Img/Tsukuba_L.png) |
|--|--|
| Tsukuba right image | ![Tsukuba right](https://github.com/Archfx/FPGA_depthMap/blob/master/Img/Tsukuba_R.png) |

Tsukuba left image
![Tsukuba left](https://github.com/Archfx/FPGA_depthMap/blob/master/Img/Tsukuba_L.png)

Tsukuba right image
![Tsukuba right](https://github.com/Archfx/FPGA_depthMap/blob/master/Img/Tsukuba_R.png)

Python results
![Colour map generated using python](https://github.com/Archfx/FPGA_depthMap/blob/master/Python_test_implementation/Disparity__colorMap_Tsukuba_5_python.jpg)
For this generation it took more than 4 seconds using an average laptop computer without any accelarating techniques.
Based on the Python implementaion Abstract flow chart is generated as follows.
![Disparity generation Flow chart](https://github.com/Archfx/FPGA_depthMap/blob/master/Img/FlowChart.png)
Then this algorithm is direclty ported to verilog. The implementation was done using ISE design suite by Xilinx. The image files were converted to hex and imported to the simulation and the output is directly saved as a Bitmap image.
Timing diagrams at 50MHz
![Verilog timing diagram](https://github.com/Archfx/FPGA_depthMap/blob/master/Img/VerilogSimulationTime.png)
Simulation Output![Verilog simulation output](https://github.com/Archfx/FPGA_depthMap/blob/master/output.png)
