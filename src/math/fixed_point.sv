//fixed point becuase floating point looks annoying and we are approximating
package fixed_point;

    typedef logic signed [16:0] fixed_t;
    localparam fixed_t FIXED_ONE = 17'sd512;
    localparam fixed_t FIXED_ZERO = 17'sd0;
    localparam fixed_t FIXED_HALF = 17'sd256;
    localparam fixed_t FIXED_MAX = 17'sd65535;
    localparam fixed_t FIXED_MIN = -17'sd65536;

endpackage
