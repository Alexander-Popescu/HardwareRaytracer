//fixed point becuase floating point looks annoying and we are approximating
package fixed_point;

    typedef logic signed [16:0] fixed_t;
    localparam fixed_t FIXED_ONE = 17'sd512;
    localparam fixed_t FIXED_ZERO = 17'sd0;
    localparam fixed_t FIXED_HALF = 17'sd256;
    localparam fixed_t FIXED_MAX = 17'sd65535;
    localparam fixed_t FIXED_MIN = -17'sd65536;

    //entry reg + 18 cycle core + 2 result regs for each math engine and alignment pipe
    localparam int PIPE_LATENCY = 21;

    //shared so shadow and diffuse agree
    localparam fixed_t LIGHT_DIR_X = 17'sd200;
    localparam fixed_t LIGHT_DIR_Y = 17'sd325;
    localparam fixed_t LIGHT_DIR_Z = 17'sd200;
    localparam fixed_t FIXED_AMBIENT = 17'sd50;

endpackage
