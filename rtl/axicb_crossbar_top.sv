// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

///////////////////////////////////////////////////////////////////////////////
//
// AXI4 crossbar top level, instanciating the global infrastructure of the
// core. All the master and slave interfaces are instanciated here along the
// switching logic.
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1 ns / 1 ps
`default_nettype none

module axicb_crossbar_top

    #(
        ///////////////////////////////////////////////////////////////////////
        // Global configuration
        ///////////////////////////////////////////////////////////////////////

        // Address width in bits
        parameter AXI_ADDR_W = 8,
        // ID width in bits
        parameter AXI_ID_W = 8,
        // Data width in bits
        parameter AXI_DATA_W = 8,

        // Number of master(s)
        parameter MST_NB = 4,
        // Number of slave(s)
        parameter SLV_NB = 4,
        // Switching logic pipelining (0 deactivate, 1 enable)
        parameter MST_PIPELINE = 0,
        parameter SLV_PIPELINE = 0,

        // STRB support:
        //   - 0: contiguous wstrb (store only 1st/last dataphase)
        //   - 1: full wstrb transport
        parameter STRB_MODE = 1,

        // AXI Signals Supported:
        //   - 0: AXI4-lite
        //   - 1: Restricted AXI4 (INCR mode only, ADDR, ALEN)
        //   - 2: Complete
        parameter AXI_SIGNALING = 0,

        // USER transport enabling (0 deactivate, 1 activate)
        parameter USER_SUPPORT = 0,
        // USER fields width in bits
        parameter AUSER_W = 1,
        parameter WUSER_W = 1,
        parameter BUSER_W = 1,
        parameter RUSER_W = 1,

        // Timeout configuration in clock cycles, applied to all channels
        parameter TIMEOUT_VALUE = 10000,
        // Activate the timer to avoid deadlock
        parameter TIMEOUT_ENABLE = 1,


        ///////////////////////////////////////////////////////////////////////
        //
        // Master configurations:
        //
        //   - MSTx_CDC: implement input CDC stage, 0 or 1
        //
        //   - MSTx_OSTDREQ_NUM: maximum number of requests a master can
        //                       store internally
        //
        //   - MSTx_OSTDREQ_SIZE: size of an outstanding request in dataphase
        //
        //   - MSTx_PRIORITY: priority applied to this master in the arbitrers,
        //                    from 0 to 3 included
        //   - MSTx_ROUTES: routing from the master to the slaves allowed in
        //                  the switching logic. Bit 0 for slave 0, bit 1 for
        //                  slave 1, ...
        //
        //   - MSTx_ID_MASK : A mask applied in slave completion channel to
        //                    determine which master to route back the
        //                    BRESP/RRESP completions.
        //
        // The size of a master's internal buffer is equal to:
        //
        // SIZE = AXI_DATA_W * MSTx_OSTDREQ_NUM * MSTx_OSTDREQ_SIZE (in bits)
        //
        ///////////////////////////////////////////////////////////////////////


        ///////////////////////////////////////////////////////////////////////
        // Master 0 configuration
        ///////////////////////////////////////////////////////////////////////

        parameter MST0_CDC = 0,
        parameter MST0_OSTDREQ_NUM = 4,
        parameter MST0_OSTDREQ_SIZE = 1,
        parameter MST0_PRIORITY = 0,
        parameter MST0_ROUTES = 4'b1_1_1_1,
        parameter [AXI_ID_W-1:0] MST0_ID_MASK = 'h00,

        ///////////////////////////////////////////////////////////////////////
        // Master 1 configuration
        ///////////////////////////////////////////////////////////////////////

        parameter MST1_CDC = 0,
        parameter MST1_OSTDREQ_NUM = 4,
        parameter MST1_OSTDREQ_SIZE = 1,
        parameter MST1_PRIORITY = 0,
        parameter MST1_ROUTES = 4'b1_1_1_1,
        parameter [AXI_ID_W-1:0] MST1_ID_MASK = 'h10,

        ///////////////////////////////////////////////////////////////////////
        // Master 2 configuration
        ///////////////////////////////////////////////////////////////////////

        parameter MST2_CDC = 0,
        parameter MST2_OSTDREQ_NUM = 4,
        parameter MST2_OSTDREQ_SIZE = 1,
        parameter MST2_PRIORITY = 0,
        parameter MST2_ROUTES = 4'b1_1_1_1,
        parameter [AXI_ID_W-1:0] MST2_ID_MASK = 'h20,

        ///////////////////////////////////////////////////////////////////////
        // Master 3 configuration
        ///////////////////////////////////////////////////////////////////////

        parameter MST3_CDC = 0,
        parameter MST3_OSTDREQ_NUM = 4,
        parameter MST3_OSTDREQ_SIZE = 1,
        parameter MST3_PRIORITY = 0,
        parameter MST3_ROUTES = 4'b1_1_1_1,
        parameter [AXI_ID_W-1:0] MST3_ID_MASK = 'h30,


        ///////////////////////////////////////////////////////////////////////
        //
        // Slave configurations:
        //
        //   - SLVx_CDC: implement input CDC stage, 0 or 1
        //
        //   - SLVx_OSTDREQ_NUM: maximum number of requests slave can
        //                       store internally
        //
        //   - SLVx_OSTDREQ_SIZE: size of an outstanding request in dataphase
        //
        //   - SLVx_START_ADDR: Start address allocated to the slave, in byte
        //
        //   - SLVx_END_ADDR: End address allocated to the slave, in byte
        //
        // The size of a slave's internal buffer is equal to:
        //
        //   AXI_DATA_W * SLVx_OSTDREQ_NUM * SLVx_OSTDREQ_SIZE (in bits)
        //
        // A request is routed to a slave if:
        //
        //   START_ADDR <= ADDR <= END_ADDR
        //
        ///////////////////////////////////////////////////////////////////////


        ///////////////////////////////////////////////////////////////////////
        // Slave 0 configuration
        ///////////////////////////////////////////////////////////////////////

        parameter SLV0_CDC = 0,
        parameter SLV0_START_ADDR = 0,
        parameter SLV0_END_ADDR = 4095,
        parameter SLV0_OSTDREQ_NUM = 4,
        parameter SLV0_OSTDREQ_SIZE = 1,

        ///////////////////////////////////////////////////////////////////////
        // Slave 1 configuration
        ///////////////////////////////////////////////////////////////////////

        parameter SLV1_CDC = 0,
        parameter SLV1_START_ADDR = 4096,
        parameter SLV1_END_ADDR = 8191,
        parameter SLV1_OSTDREQ_NUM = 4,
        parameter SLV1_OSTDREQ_SIZE = 1,

        ///////////////////////////////////////////////////////////////////////
        // Slave 2 configuration
        ///////////////////////////////////////////////////////////////////////

        parameter SLV2_CDC = 0,
        parameter SLV2_START_ADDR = 8192,
        parameter SLV2_END_ADDR = 12287,
        parameter SLV2_OSTDREQ_NUM = 4,
        parameter SLV2_OSTDREQ_SIZE = 1,

        ///////////////////////////////////////////////////////////////////////
        // Slave 3 configuration
        ///////////////////////////////////////////////////////////////////////

        parameter SLV3_CDC = 0,
        parameter SLV3_START_ADDR = 12288,
        parameter SLV3_END_ADDR = 16383,
        parameter SLV3_OSTDREQ_NUM = 4,
        parameter SLV3_OSTDREQ_SIZE = 1
    )(
        ///////////////////////////////////////////////////////////////////////
        // Interconnect global interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      aclk,
        input  logic                      aresetn,
        input  logic                      srst,

        ///////////////////////////////////////////////////////////////////////
        // Master 0 interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      mst0_aclk,
        input  logic                      mst0_aresetn,
        input  logic                      mst0_srst,
        input  logic                      mst0_awvalid,
        output logic                      mst0_awready,
        input  logic [AXI_ADDR_W    -1:0] mst0_awaddr,
        input  logic [8             -1:0] mst0_awlen,
        input  logic [3             -1:0] mst0_awsize,
        input  logic [2             -1:0] mst0_awburst,
        input  logic [2             -1:0] mst0_awlock,
        input  logic [4             -1:0] mst0_awcache,
        input  logic [3             -1:0] mst0_awprot,
        input  logic [4             -1:0] mst0_awqos,
        input  logic [4             -1:0] mst0_awregion,
        input  logic [AXI_ID_W      -1:0] mst0_awid,
        input  logic                      mst0_wvalid,
        output logic                      mst0_wready,
        input  logic                      mst0_wlast,
        input  logic [AXI_DATA_W    -1:0] mst0_wdata,
        input  logic [AXI_DATA_W/8  -1:0] mst0_wstrb,
        output logic                      mst0_bvalid,
        input  logic                      mst0_bready,
        output logic [AXI_ID_W      -1:0] mst0_bid,
        output logic [2             -1:0] mst0_bresp,
        input  logic                      mst0_arvalid,
        output logic                      mst0_arready,
        input  logic [AXI_ADDR_W    -1:0] mst0_araddr,
        input  logic [8             -1:0] mst0_arlen,
        input  logic [3             -1:0] mst0_arsize,
        input  logic [2             -1:0] mst0_arburst,
        input  logic [2             -1:0] mst0_arlock,
        input  logic [4             -1:0] mst0_arcache,
        input  logic [3             -1:0] mst0_arprot,
        input  logic [4             -1:0] mst0_arqos,
        input  logic [4             -1:0] mst0_arregion,
        input  logic [AXI_ID_W      -1:0] mst0_arid,
        output logic                      mst0_rvalid,
        input  logic                      mst0_rready,
        output logic [AXI_ID_W      -1:0] mst0_rid,
        output logic [2             -1:0] mst0_rresp,
        output logic [AXI_DATA_W    -1:0] mst0_rdata,
        output logic                      mst0_rlast,

        ///////////////////////////////////////////////////////////////////////
        // Master 1 interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      mst1_aclk,
        input  logic                      mst1_aresetn,
        input  logic                      mst1_srst,
        input  logic                      mst1_awvalid,
        output logic                      mst1_awready,
        input  logic [AXI_ADDR_W    -1:0] mst1_awaddr,
        input  logic [8             -1:0] mst1_awlen,
        input  logic [3             -1:0] mst1_awsize,
        input  logic [2             -1:0] mst1_awburst,
        input  logic [2             -1:0] mst1_awlock,
        input  logic [4             -1:0] mst1_awcache,
        input  logic [3             -1:0] mst1_awprot,
        input  logic [4             -1:0] mst1_awqos,
        input  logic [4             -1:0] mst1_awregion,
        input  logic [AXI_ID_W      -1:0] mst1_awid,
        input  logic                      mst1_wvalid,
        output logic                      mst1_wready,
        input  logic                      mst1_wlast,
        input  logic [AXI_DATA_W    -1:0] mst1_wdata,
        input  logic [AXI_DATA_W/8  -1:0] mst1_wstrb,
        output logic                      mst1_bvalid,
        input  logic                      mst1_bready,
        output logic [AXI_ID_W      -1:0] mst1_bid,
        output logic [2             -1:0] mst1_bresp,
        input  logic                      mst1_arvalid,
        output logic                      mst1_arready,
        input  logic [AXI_ADDR_W    -1:0] mst1_araddr,
        input  logic [8             -1:0] mst1_arlen,
        input  logic [3             -1:0] mst1_arsize,
        input  logic [2             -1:0] mst1_arburst,
        input  logic [2             -1:0] mst1_arlock,
        input  logic [4             -1:0] mst1_arcache,
        input  logic [3             -1:0] mst1_arprot,
        input  logic [4             -1:0] mst1_arqos,
        input  logic [4             -1:0] mst1_arregion,
        input  logic [AXI_ID_W      -1:0] mst1_arid,
        output logic                      mst1_rvalid,
        input  logic                      mst1_rready,
        output logic [AXI_ID_W      -1:0] mst1_rid,
        output logic [2             -1:0] mst1_rresp,
        output logic [AXI_DATA_W    -1:0] mst1_rdata,
        output logic                      mst1_rlast,

        ///////////////////////////////////////////////////////////////////////
        // Master 1 interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      mst2_aclk,
        input  logic                      mst2_aresetn,
        input  logic                      mst2_srst,
        input  logic                      mst2_awvalid,
        output logic                      mst2_awready,
        input  logic [AXI_ADDR_W    -1:0] mst2_awaddr,
        input  logic [8             -1:0] mst2_awlen,
        input  logic [3             -1:0] mst2_awsize,
        input  logic [2             -1:0] mst2_awburst,
        input  logic [2             -1:0] mst2_awlock,
        input  logic [4             -1:0] mst2_awcache,
        input  logic [3             -1:0] mst2_awprot,
        input  logic [4             -1:0] mst2_awqos,
        input  logic [4             -1:0] mst2_awregion,
        input  logic [AXI_ID_W      -1:0] mst2_awid,
        input  logic                      mst2_wvalid,
        output logic                      mst2_wready,
        input  logic                      mst2_wlast,
        input  logic [AXI_DATA_W    -1:0] mst2_wdata,
        input  logic [AXI_DATA_W/8  -1:0] mst2_wstrb,
        output logic                      mst2_bvalid,
        input  logic                      mst2_bready,
        output logic [AXI_ID_W      -1:0] mst2_bid,
        output logic [2             -1:0] mst2_bresp,
        input  logic                      mst2_arvalid,
        output logic                      mst2_arready,
        input  logic [AXI_ADDR_W    -1:0] mst2_araddr,
        input  logic [8             -1:0] mst2_arlen,
        input  logic [3             -1:0] mst2_arsize,
        input  logic [2             -1:0] mst2_arburst,
        input  logic [2             -1:0] mst2_arlock,
        input  logic [4             -1:0] mst2_arcache,
        input  logic [3             -1:0] mst2_arprot,
        input  logic [4             -1:0] mst2_arqos,
        input  logic [4             -1:0] mst2_arregion,
        input  logic [AXI_ID_W      -1:0] mst2_arid,
        output logic                      mst2_rvalid,
        input  logic                      mst2_rready,
        output logic [AXI_ID_W      -1:0] mst2_rid,
        output logic [2             -1:0] mst2_rresp,
        output logic [AXI_DATA_W    -1:0] mst2_rdata,
        output logic                      mst2_rlast,

        ///////////////////////////////////////////////////////////////////////
        // Master 1 interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      mst3_aclk,
        input  logic                      mst3_aresetn,
        input  logic                      mst3_srst,
        input  logic                      mst3_awvalid,
        output logic                      mst3_awready,
        input  logic [AXI_ADDR_W    -1:0] mst3_awaddr,
        input  logic [8             -1:0] mst3_awlen,
        input  logic [3             -1:0] mst3_awsize,
        input  logic [2             -1:0] mst3_awburst,
        input  logic [2             -1:0] mst3_awlock,
        input  logic [4             -1:0] mst3_awcache,
        input  logic [3             -1:0] mst3_awprot,
        input  logic [4             -1:0] mst3_awqos,
        input  logic [4             -1:0] mst3_awregion,
        input  logic [AXI_ID_W      -1:0] mst3_awid,
        input  logic                      mst3_wvalid,
        output logic                      mst3_wready,
        input  logic                      mst3_wlast,
        input  logic [AXI_DATA_W    -1:0] mst3_wdata,
        input  logic [AXI_DATA_W/8  -1:0] mst3_wstrb,
        output logic                      mst3_bvalid,
        input  logic                      mst3_bready,
        output logic [AXI_ID_W      -1:0] mst3_bid,
        output logic [2             -1:0] mst3_bresp,
        input  logic                      mst3_arvalid,
        output logic                      mst3_arready,
        input  logic [AXI_ADDR_W    -1:0] mst3_araddr,
        input  logic [8             -1:0] mst3_arlen,
        input  logic [3             -1:0] mst3_arsize,
        input  logic [2             -1:0] mst3_arburst,
        input  logic [2             -1:0] mst3_arlock,
        input  logic [4             -1:0] mst3_arcache,
        input  logic [3             -1:0] mst3_arprot,
        input  logic [4             -1:0] mst3_arqos,
        input  logic [4             -1:0] mst3_arregion,
        input  logic [AXI_ID_W      -1:0] mst3_arid,
        output logic                      mst3_rvalid,
        input  logic                      mst3_rready,
        output logic [AXI_ID_W      -1:0] mst3_rid,
        output logic [2             -1:0] mst3_rresp,
        output logic [AXI_DATA_W    -1:0] mst3_rdata,
        output logic                      mst3_rlast,

        ///////////////////////////////////////////////////////////////////////
        // Slave 0 interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      slv0_aclk,
        input  logic                      slv0_aresetn,
        input  logic                      slv0_srst,
        output logic                      slv0_awvalid,
        input  logic                      slv0_awready,
        output logic [AXI_ADDR_W    -1:0] slv0_awaddr,
        output logic [8             -1:0] slv0_awlen,
        output logic [3             -1:0] slv0_awsize,
        output logic [2             -1:0] slv0_awburst,
        output logic [2             -1:0] slv0_awlock,
        output logic [4             -1:0] slv0_awcache,
        output logic [3             -1:0] slv0_awprot,
        output logic [4             -1:0] slv0_awqos,
        output logic [4             -1:0] slv0_awregion,
        output logic [AXI_ID_W      -1:0] slv0_awid,
        output logic                      slv0_wvalid,
        input  logic                      slv0_wready,
        output logic                      slv0_wlast,
        output logic [AXI_DATA_W    -1:0] slv0_wdata,
        output logic [AXI_DATA_W/8  -1:0] slv0_wstrb,
        input  logic                      slv0_bvalid,
        output logic                      slv0_bready,
        input  logic [AXI_ID_W      -1:0] slv0_bid,
        input  logic [2             -1:0] slv0_bresp,
        output logic                      slv0_arvalid,
        input  logic                      slv0_arready,
        output logic [AXI_ADDR_W    -1:0] slv0_araddr,
        output logic [8             -1:0] slv0_arlen,
        output logic [3             -1:0] slv0_arsize,
        output logic [2             -1:0] slv0_arburst,
        output logic [2             -1:0] slv0_arlock,
        output logic [4             -1:0] slv0_arcache,
        output logic [3             -1:0] slv0_arprot,
        output logic [4             -1:0] slv0_arqos,
        output logic [4             -1:0] slv0_arregion,
        output logic [AXI_ID_W      -1:0] slv0_arid,
        input  logic                      slv0_rvalid,
        output logic                      slv0_rready,
        input  logic [AXI_ID_W      -1:0] slv0_rid,
        input  logic [2             -1:0] slv0_rresp,
        input  logic [AXI_DATA_W    -1:0] slv0_rdata,
        input  logic                      slv0_rlast,

        ///////////////////////////////////////////////////////////////////////
        // Slave 1 interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      slv1_aclk,
        input  logic                      slv1_aresetn,
        input  logic                      slv1_srst,
        output logic                      slv1_awvalid,
        input  logic                      slv1_awready,
        output logic [AXI_ADDR_W    -1:0] slv1_awaddr,
        output logic [8             -1:0] slv1_awlen,
        output logic [3             -1:0] slv1_awsize,
        output logic [2             -1:0] slv1_awburst,
        output logic [2             -1:0] slv1_awlock,
        output logic [4             -1:0] slv1_awcache,
        output logic [3             -1:0] slv1_awprot,
        output logic [4             -1:0] slv1_awqos,
        output logic [4             -1:0] slv1_awregion,
        output logic [AXI_ID_W      -1:0] slv1_awid,
        output logic                      slv1_wvalid,
        input  logic                      slv1_wready,
        output logic                      slv1_wlast,
        output logic [AXI_DATA_W    -1:0] slv1_wdata,
        output logic [AXI_DATA_W/8  -1:0] slv1_wstrb,
        input  logic                      slv1_bvalid,
        output logic                      slv1_bready,
        input  logic [AXI_ID_W      -1:0] slv1_bid,
        input  logic [2             -1:0] slv1_bresp,
        output logic                      slv1_arvalid,
        input  logic                      slv1_arready,
        output logic [AXI_ADDR_W    -1:0] slv1_araddr,
        output logic [8             -1:0] slv1_arlen,
        output logic [3             -1:0] slv1_arsize,
        output logic [2             -1:0] slv1_arburst,
        output logic [2             -1:0] slv1_arlock,
        output logic [4             -1:0] slv1_arcache,
        output logic [3             -1:0] slv1_arprot,
        output logic [4             -1:0] slv1_arqos,
        output logic [4             -1:0] slv1_arregion,
        output logic [AXI_ID_W      -1:0] slv1_arid,
        input  logic                      slv1_rvalid,
        output logic                      slv1_rready,
        input  logic [AXI_ID_W      -1:0] slv1_rid,
        input  logic [2             -1:0] slv1_rresp,
        input  logic [AXI_DATA_W    -1:0] slv1_rdata,
        input  logic                      slv1_rlast,

        ///////////////////////////////////////////////////////////////////////
        // Slave 2 interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      slv2_aclk,
        input  logic                      slv2_aresetn,
        input  logic                      slv2_srst,
        output logic                      slv2_awvalid,
        input  logic                      slv2_awready,
        output logic [AXI_ADDR_W    -1:0] slv2_awaddr,
        output logic [8             -1:0] slv2_awlen,
        output logic [3             -1:0] slv2_awsize,
        output logic [2             -1:0] slv2_awburst,
        output logic [2             -1:0] slv2_awlock,
        output logic [4             -1:0] slv2_awcache,
        output logic [3             -1:0] slv2_awprot,
        output logic [4             -1:0] slv2_awqos,
        output logic [4             -1:0] slv2_awregion,
        output logic [AXI_ID_W      -1:0] slv2_awid,
        output logic                      slv2_wvalid,
        input  logic                      slv2_wready,
        output logic                      slv2_wlast,
        output logic [AXI_DATA_W    -1:0] slv2_wdata,
        output logic [AXI_DATA_W/8  -1:0] slv2_wstrb,
        input  logic                      slv2_bvalid,
        output logic                      slv2_bready,
        input  logic [AXI_ID_W      -1:0] slv2_bid,
        input  logic [2             -1:0] slv2_bresp,
        output logic                      slv2_arvalid,
        input  logic                      slv2_arready,
        output logic [AXI_ADDR_W    -1:0] slv2_araddr,
        output logic [8             -1:0] slv2_arlen,
        output logic [3             -1:0] slv2_arsize,
        output logic [2             -1:0] slv2_arburst,
        output logic [2             -1:0] slv2_arlock,
        output logic [4             -1:0] slv2_arcache,
        output logic [3             -1:0] slv2_arprot,
        output logic [4             -1:0] slv2_arqos,
        output logic [4             -1:0] slv2_arregion,
        output logic [AXI_ID_W      -1:0] slv2_arid,
        input  logic                      slv2_rvalid,
        output logic                      slv2_rready,
        input  logic [AXI_ID_W      -1:0] slv2_rid,
        input  logic [2             -1:0] slv2_rresp,
        input  logic [AXI_DATA_W    -1:0] slv2_rdata,
        input  logic                      slv2_rlast,

        ///////////////////////////////////////////////////////////////////////
        // Slave 3 interface
        ///////////////////////////////////////////////////////////////////////

        input  logic                      slv3_aclk,
        input  logic                      slv3_aresetn,
        input  logic                      slv3_srst,
        output logic                      slv3_awvalid,
        input  logic                      slv3_awready,
        output logic [AXI_ADDR_W    -1:0] slv3_awaddr,
        output logic [8             -1:0] slv3_awlen,
        output logic [3             -1:0] slv3_awsize,
        output logic [2             -1:0] slv3_awburst,
        output logic [2             -1:0] slv3_awlock,
        output logic [4             -1:0] slv3_awcache,
        output logic [3             -1:0] slv3_awprot,
        output logic [4             -1:0] slv3_awqos,
        output logic [4             -1:0] slv3_awregion,
        output logic [AXI_ID_W      -1:0] slv3_awid,
        output logic                      slv3_wvalid,
        input  logic                      slv3_wready,
        output logic                      slv3_wlast,
        output logic [AXI_DATA_W    -1:0] slv3_wdata,
        output logic [AXI_DATA_W/8  -1:0] slv3_wstrb,
        input  logic                      slv3_bvalid,
        output logic                      slv3_bready,
        input  logic [AXI_ID_W      -1:0] slv3_bid,
        input  logic [2             -1:0] slv3_bresp,
        output logic                      slv3_arvalid,
        input  logic                      slv3_arready,
        output logic [AXI_ADDR_W    -1:0] slv3_araddr,
        output logic [8             -1:0] slv3_arlen,
        output logic [3             -1:0] slv3_arsize,
        output logic [2             -1:0] slv3_arburst,
        output logic [2             -1:0] slv3_arlock,
        output logic [4             -1:0] slv3_arcache,
        output logic [3             -1:0] slv3_arprot,
        output logic [4             -1:0] slv3_arqos,
        output logic [4             -1:0] slv3_arregion,
        output logic [AXI_ID_W      -1:0] slv3_arid,
        input  logic                      slv3_rvalid,
        output logic                      slv3_rready,
        input  logic [AXI_ID_W      -1:0] slv3_rid,
        input  logic [2             -1:0] slv3_rresp,
        input  logic [AXI_DATA_W    -1:0] slv3_rdata,
        input  logic                      slv3_rlast
    );


    ///////////////////////////////////////////////////////////////////////////
    // Local declarations
    ///////////////////////////////////////////////////////////////////////////

    localparam AWCH_W = // AXI4-lite signaling only: ADDR + ID + APROT
                        (AXI_SIGNALING==0) ? AXI_ADDR_W + AXI_ID_W + 3:
                        // AXI4-lite + BURST mode (INCR mode only)
                        (AXI_SIGNALING==1) ? AXI_ADDR_W + AXI_ID_W + 11:
                        // Complete AXI4 signaling
                                             AXI_ADDR_W + AXI_ID_W + 30;

    localparam WCH_W = AXI_DATA_W + AXI_DATA_W/8;

    localparam BCH_W = AXI_ID_W + 2;

    localparam ARCH_W = AWCH_W;

    localparam RCH_W = AXI_DATA_W + AXI_ID_W + 2;

    logic [MST_NB            -1:0] i_awvalid;
    logic [MST_NB            -1:0] i_awready;
    logic [MST_NB*AWCH_W     -1:0] i_awch;
    logic [MST_NB            -1:0] i_wvalid;
    logic [MST_NB            -1:0] i_wready;
    logic [MST_NB            -1:0] i_wlast;
    logic [MST_NB*WCH_W      -1:0] i_wch;
    logic [MST_NB            -1:0] i_bvalid;
    logic [MST_NB            -1:0] i_bready;
    logic [MST_NB*BCH_W      -1:0] i_bch;
    logic [MST_NB            -1:0] i_arvalid;
    logic [MST_NB            -1:0] i_arready;
    logic [MST_NB*ARCH_W     -1:0] i_arch;
    logic [MST_NB            -1:0] i_rvalid;
    logic [MST_NB            -1:0] i_rready;
    logic [MST_NB            -1:0] i_rlast;
    logic [MST_NB*RCH_W      -1:0] i_rch;
    logic [SLV_NB            -1:0] o_awvalid;
    logic [SLV_NB            -1:0] o_awready;
    logic [SLV_NB*AWCH_W     -1:0] o_awch;
    logic [SLV_NB            -1:0] o_wvalid;
    logic [SLV_NB            -1:0] o_wready;
    logic [SLV_NB            -1:0] o_wlast;
    logic [SLV_NB*WCH_W      -1:0] o_wch;
    logic [SLV_NB            -1:0] o_bvalid;
    logic [SLV_NB            -1:0] o_bready;
    logic [SLV_NB*BCH_W      -1:0] o_bch;
    logic [SLV_NB            -1:0] o_arvalid;
    logic [SLV_NB            -1:0] o_arready;
    logic [SLV_NB*ARCH_W     -1:0] o_arch;
    logic [SLV_NB            -1:0] o_rvalid;
    logic [SLV_NB            -1:0] o_rready;
    logic [SLV_NB            -1:0] o_rlast;
    logic [SLV_NB*RCH_W      -1:0] o_rch;


    ///////////////////////////////////////////////////////////////////////////
    // Master interface 0
    ///////////////////////////////////////////////////////////////////////////

    axicb_mst_if
    #(
    .AXI_ADDR_W        (AXI_ADDR_W),
    .AXI_ID_W          (AXI_ID_W),
    .AXI_DATA_W        (AXI_DATA_W),
    .SLV_NB            (SLV_NB),
    .STRB_MODE         (STRB_MODE),
    .AXI_SIGNALING     (AXI_SIGNALING),
    .TIMEOUT_ENABLE    (TIMEOUT_ENABLE),
    .MST_CDC           (MST0_CDC),
    .MST_OSTDREQ_NUM   (MST0_OSTDREQ_NUM),
    .MST_OSTDREQ_SIZE  (MST0_OSTDREQ_SIZE),
    .AWCH_W            (AWCH_W),
    .WCH_W             (WCH_W),
    .BCH_W             (BCH_W),
    .ARCH_W            (ARCH_W),
    .RCH_W             (RCH_W)
    )
    mst0_if
    (
    .i_aclk       (mst0_aclk),
    .i_aresetn    (mst0_aresetn),
    .i_srst       (mst0_srst),
    .i_awvalid    (mst0_awvalid),
    .i_awready    (mst0_awready),
    .i_awaddr     (mst0_awaddr),
    .i_awlen      (mst0_awlen),
    .i_awsize     (mst0_awsize),
    .i_awburst    (mst0_awburst),
    .i_awlock     (mst0_awlock),
    .i_awcache    (mst0_awcache),
    .i_awprot     (mst0_awprot),
    .i_awqos      (mst0_awqos),
    .i_awregion   (mst0_awregion),
    .i_awid       (mst0_awid),
    .i_wvalid     (mst0_wvalid),
    .i_wready     (mst0_wready),
    .i_wlast      (mst0_wlast ),
    .i_wdata      (mst0_wdata),
    .i_wstrb      (mst0_wstrb),
    .i_bvalid     (mst0_bvalid),
    .i_bready     (mst0_bready),
    .i_bid        (mst0_bid),
    .i_bresp      (mst0_bresp),
    .i_arvalid    (mst0_arvalid),
    .i_arready    (mst0_arready),
    .i_araddr     (mst0_araddr),
    .i_arlen      (mst0_arlen),
    .i_arsize     (mst0_arsize),
    .i_arburst    (mst0_arburst),
    .i_arlock     (mst0_arlock),
    .i_arcache    (mst0_arcache),
    .i_arprot     (mst0_arprot),
    .i_arqos      (mst0_arqos),
    .i_arregion   (mst0_arregion),
    .i_arid       (mst0_arid),
    .i_rvalid     (mst0_rvalid),
    .i_rready     (mst0_rready),
    .i_rid        (mst0_rid),
    .i_rresp      (mst0_rresp),
    .i_rdata      (mst0_rdata),
    .i_rlast      (mst0_rlast),
    .o_aclk       (aclk),
    .o_aresetn    (aresetn),
    .o_srst       (srst),
    .o_awvalid    (i_awvalid[0]),
    .o_awready    (i_awready[0]),
    .o_awch       (i_awch[0*AWCH_W+:AWCH_W]),
    .o_wvalid     (i_wvalid[0]),
    .o_wready     (i_wready[0]),
    .o_wlast      (i_wlast[0]),
    .o_wch        (i_wch[0*WCH_W+:WCH_W]),
    .o_bvalid     (i_bvalid[0]),
    .o_bready     (i_bready[0]),
    .o_bch        (i_bch[0*BCH_W+:BCH_W]),
    .o_arvalid    (i_arvalid[0]),
    .o_arready    (i_arready[0]),
    .o_arch       (i_arch[0*ARCH_W+:ARCH_W]),
    .o_rvalid     (i_rvalid[0]),
    .o_rready     (i_rready[0]),
    .o_rlast      (i_rlast[0]),
    .o_rch        (i_rch[0*RCH_W+:RCH_W])
    );

    ///////////////////////////////////////////////////////////////////////////
    // Master interface 1
    ///////////////////////////////////////////////////////////////////////////

    axicb_mst_if
    #(
    .AXI_ADDR_W        (AXI_ADDR_W),
    .AXI_ID_W          (AXI_ID_W),
    .AXI_DATA_W        (AXI_DATA_W),
    .SLV_NB            (SLV_NB),
    .STRB_MODE         (STRB_MODE),
    .AXI_SIGNALING     (AXI_SIGNALING),
    .TIMEOUT_ENABLE    (TIMEOUT_ENABLE),
    .MST_CDC           (MST1_CDC),
    .MST_OSTDREQ_NUM   (MST1_OSTDREQ_NUM),
    .MST_OSTDREQ_SIZE  (MST1_OSTDREQ_SIZE),
    .AWCH_W            (AWCH_W),
    .WCH_W             (WCH_W),
    .BCH_W             (BCH_W),
    .ARCH_W            (ARCH_W),
    .RCH_W             (RCH_W)
    )
    mst1_if
    (
    .i_aclk       (mst1_aclk),
    .i_aresetn    (mst1_aresetn),
    .i_srst       (mst1_srst),
    .i_awvalid    (mst1_awvalid),
    .i_awready    (mst1_awready),
    .i_awaddr     (mst1_awaddr),
    .i_awlen      (mst1_awlen),
    .i_awsize     (mst1_awsize),
    .i_awburst    (mst1_awburst),
    .i_awlock     (mst1_awlock),
    .i_awcache    (mst1_awcache),
    .i_awprot     (mst1_awprot),
    .i_awqos      (mst1_awqos),
    .i_awregion   (mst1_awregion),
    .i_awid       (mst1_awid),
    .i_wvalid     (mst1_wvalid),
    .i_wready     (mst1_wready),
    .i_wlast      (mst1_wlast ),
    .i_wdata      (mst1_wdata),
    .i_wstrb      (mst1_wstrb),
    .i_bvalid     (mst1_bvalid),
    .i_bready     (mst1_bready),
    .i_bid        (mst1_bid),
    .i_bresp      (mst1_bresp),
    .i_arvalid    (mst1_arvalid),
    .i_arready    (mst1_arready),
    .i_araddr     (mst1_araddr),
    .i_arlen      (mst1_arlen),
    .i_arsize     (mst1_arsize),
    .i_arburst    (mst1_arburst),
    .i_arlock     (mst1_arlock),
    .i_arcache    (mst1_arcache),
    .i_arprot     (mst1_arprot),
    .i_arqos      (mst1_arqos),
    .i_arregion   (mst1_arregion),
    .i_arid       (mst1_arid),
    .i_rvalid     (mst1_rvalid),
    .i_rready     (mst1_rready),
    .i_rid        (mst1_rid),
    .i_rresp      (mst1_rresp),
    .i_rdata      (mst1_rdata),
    .i_rlast      (mst1_rlast),
    .o_aclk       (aclk),
    .o_aresetn    (aresetn),
    .o_srst       (srst),
    .o_awvalid    (i_awvalid[1]),
    .o_awready    (i_awready[1]),
    .o_awch       (i_awch[1*AWCH_W+:AWCH_W]),
    .o_wvalid     (i_wvalid[1]),
    .o_wready     (i_wready[1]),
    .o_wlast      (i_wlast[1]),
    .o_wch        (i_wch[1*WCH_W+:WCH_W]),
    .o_bvalid     (i_bvalid[1]),
    .o_bready     (i_bready[1]),
    .o_bch        (i_bch[1*BCH_W+:BCH_W]),
    .o_arvalid    (i_arvalid[1]),
    .o_arready    (i_arready[1]),
    .o_arch       (i_arch[1*ARCH_W+:ARCH_W]),
    .o_rvalid     (i_rvalid[1]),
    .o_rready     (i_rready[1]),
    .o_rlast      (i_rlast[1]),
    .o_rch        (i_rch[1*RCH_W+:RCH_W])
    );

    ///////////////////////////////////////////////////////////////////////////
    // Master interface 2
    ///////////////////////////////////////////////////////////////////////////

    axicb_mst_if
    #(
    .AXI_ADDR_W        (AXI_ADDR_W),
    .AXI_ID_W          (AXI_ID_W),
    .AXI_DATA_W        (AXI_DATA_W),
    .SLV_NB            (SLV_NB),
    .STRB_MODE         (STRB_MODE),
    .AXI_SIGNALING     (AXI_SIGNALING),
    .TIMEOUT_ENABLE    (TIMEOUT_ENABLE),
    .MST_CDC           (MST2_CDC),
    .MST_OSTDREQ_NUM   (MST2_OSTDREQ_NUM),
    .MST_OSTDREQ_SIZE  (MST2_OSTDREQ_SIZE),
    .AWCH_W            (AWCH_W),
    .WCH_W             (WCH_W),
    .BCH_W             (BCH_W),
    .ARCH_W            (ARCH_W),
    .RCH_W             (RCH_W)
    )
    mst2_if
    (
    .i_aclk       (mst2_aclk),
    .i_aresetn    (mst2_aresetn),
    .i_srst       (mst2_srst),
    .i_awvalid    (mst2_awvalid),
    .i_awready    (mst2_awready),
    .i_awaddr     (mst2_awaddr),
    .i_awlen      (mst2_awlen),
    .i_awsize     (mst2_awsize),
    .i_awburst    (mst2_awburst),
    .i_awlock     (mst2_awlock),
    .i_awcache    (mst2_awcache),
    .i_awprot     (mst2_awprot),
    .i_awqos      (mst2_awqos),
    .i_awregion   (mst2_awregion),
    .i_awid       (mst2_awid),
    .i_wvalid     (mst2_wvalid),
    .i_wready     (mst2_wready),
    .i_wlast      (mst2_wlast ),
    .i_wdata      (mst2_wdata),
    .i_wstrb      (mst2_wstrb),
    .i_bvalid     (mst2_bvalid),
    .i_bready     (mst2_bready),
    .i_bid        (mst2_bid),
    .i_bresp      (mst2_bresp),
    .i_arvalid    (mst2_arvalid),
    .i_arready    (mst2_arready),
    .i_araddr     (mst2_araddr),
    .i_arlen      (mst2_arlen),
    .i_arsize     (mst2_arsize),
    .i_arburst    (mst2_arburst),
    .i_arlock     (mst2_arlock),
    .i_arcache    (mst2_arcache),
    .i_arprot     (mst2_arprot),
    .i_arqos      (mst2_arqos),
    .i_arregion   (mst2_arregion),
    .i_arid       (mst2_arid),
    .i_rvalid     (mst2_rvalid),
    .i_rready     (mst2_rready),
    .i_rid        (mst2_rid),
    .i_rresp      (mst2_rresp),
    .i_rdata      (mst2_rdata),
    .i_rlast      (mst2_rlast),
    .o_aclk       (aclk),
    .o_aresetn    (aresetn),
    .o_srst       (srst),
    .o_awvalid    (i_awvalid[2]),
    .o_awready    (i_awready[2]),
    .o_awch       (i_awch[2*AWCH_W+:AWCH_W]),
    .o_wvalid     (i_wvalid[2]),
    .o_wready     (i_wready[2]),
    .o_wlast      (i_wlast[2]),
    .o_wch        (i_wch[2*WCH_W+:WCH_W]),
    .o_bvalid     (i_bvalid[2]),
    .o_bready     (i_bready[2]),
    .o_bch        (i_bch[2*BCH_W+:BCH_W]),
    .o_arvalid    (i_arvalid[2]),
    .o_arready    (i_arready[2]),
    .o_arch       (i_arch[2*ARCH_W+:ARCH_W]),
    .o_rvalid     (i_rvalid[2]),
    .o_rready     (i_rready[2]),
    .o_rlast      (i_rlast[2]),
    .o_rch        (i_rch[2*RCH_W+:RCH_W])
    );

    ///////////////////////////////////////////////////////////////////////////
    // Master interface 3
    ///////////////////////////////////////////////////////////////////////////

    axicb_mst_if
    #(
    .AXI_ADDR_W        (AXI_ADDR_W),
    .AXI_ID_W          (AXI_ID_W),
    .AXI_DATA_W        (AXI_DATA_W),
    .SLV_NB            (SLV_NB),
    .STRB_MODE         (STRB_MODE),
    .AXI_SIGNALING     (AXI_SIGNALING),
    .TIMEOUT_ENABLE    (TIMEOUT_ENABLE),
    .MST_CDC           (MST3_CDC),
    .MST_OSTDREQ_NUM   (MST3_OSTDREQ_NUM),
    .MST_OSTDREQ_SIZE  (MST3_OSTDREQ_SIZE),
    .AWCH_W            (AWCH_W),
    .WCH_W             (WCH_W),
    .BCH_W             (BCH_W),
    .ARCH_W            (ARCH_W),
    .RCH_W             (RCH_W)
    )
    mst3_if
    (
    .i_aclk       (mst3_aclk),
    .i_aresetn    (mst3_aresetn),
    .i_srst       (mst3_srst),
    .i_awvalid    (mst3_awvalid),
    .i_awready    (mst3_awready),
    .i_awaddr     (mst3_awaddr),
    .i_awlen      (mst3_awlen),
    .i_awsize     (mst3_awsize),
    .i_awburst    (mst3_awburst),
    .i_awlock     (mst3_awlock),
    .i_awcache    (mst3_awcache),
    .i_awprot     (mst3_awprot),
    .i_awqos      (mst3_awqos),
    .i_awregion   (mst3_awregion),
    .i_awid       (mst3_awid),
    .i_wvalid     (mst3_wvalid),
    .i_wready     (mst3_wready),
    .i_wlast      (mst3_wlast ),
    .i_wdata      (mst3_wdata),
    .i_wstrb      (mst3_wstrb),
    .i_bvalid     (mst3_bvalid),
    .i_bready     (mst3_bready),
    .i_bid        (mst3_bid),
    .i_bresp      (mst3_bresp),
    .i_arvalid    (mst3_arvalid),
    .i_arready    (mst3_arready),
    .i_araddr     (mst3_araddr),
    .i_arlen      (mst3_arlen),
    .i_arsize     (mst3_arsize),
    .i_arburst    (mst3_arburst),
    .i_arlock     (mst3_arlock),
    .i_arcache    (mst3_arcache),
    .i_arprot     (mst3_arprot),
    .i_arqos      (mst3_arqos),
    .i_arregion   (mst3_arregion),
    .i_arid       (mst3_arid),
    .i_rvalid     (mst3_rvalid),
    .i_rready     (mst3_rready),
    .i_rid        (mst3_rid),
    .i_rresp      (mst3_rresp),
    .i_rdata      (mst3_rdata),
    .i_rlast      (mst3_rlast),
    .o_aclk       (aclk),
    .o_aresetn    (aresetn),
    .o_srst       (srst),
    .o_awvalid    (i_awvalid[3]),
    .o_awready    (i_awready[3]),
    .o_awch       (i_awch[3*AWCH_W+:AWCH_W]),
    .o_wvalid     (i_wvalid[3]),
    .o_wready     (i_wready[3]),
    .o_wlast      (i_wlast[3]),
    .o_wch        (i_wch[3*WCH_W+:WCH_W]),
    .o_bvalid     (i_bvalid[3]),
    .o_bready     (i_bready[3]),
    .o_bch        (i_bch[3*BCH_W+:BCH_W]),
    .o_arvalid    (i_arvalid[3]),
    .o_arready    (i_arready[3]),
    .o_arch       (i_arch[3*ARCH_W+:ARCH_W]),
    .o_rvalid     (i_rvalid[3]),
    .o_rready     (i_rready[3]),
    .o_rlast      (i_rlast[3]),
    .o_rch        (i_rch[3*RCH_W+:RCH_W])
    );

    ///////////////////////////////////////////////////////////////////////////
    // AXI channels switching logic
    ///////////////////////////////////////////////////////////////////////////

    axicb_switch_top
    #(
    .AXI_ADDR_W         (AXI_ADDR_W),
    .AXI_ID_W           (AXI_ID_W),
    .AXI_DATA_W         (AXI_DATA_W),
    .MST_NB             (MST_NB),
    .SLV_NB             (SLV_NB),
    .MST_PIPELINE       (MST_PIPELINE),
    .SLV_PIPELINE       (SLV_PIPELINE),
    .TIMEOUT_ENABLE     (TIMEOUT_ENABLE),
    .MST0_ID_MASK       (MST0_ID_MASK),
    .MST1_ID_MASK       (MST1_ID_MASK),
    .MST2_ID_MASK       (MST2_ID_MASK),
    .MST3_ID_MASK       (MST3_ID_MASK),
    .MST0_PRIORITY      (MST0_PRIORITY),
    .MST1_PRIORITY      (MST1_PRIORITY),
    .MST2_PRIORITY      (MST2_PRIORITY),
    .MST3_PRIORITY      (MST3_PRIORITY),
    .SLV0_START_ADDR    (SLV0_START_ADDR),
    .SLV0_END_ADDR      (SLV0_END_ADDR),
    .SLV1_START_ADDR    (SLV1_START_ADDR),
    .SLV1_END_ADDR      (SLV1_END_ADDR),
    .SLV2_START_ADDR    (SLV2_START_ADDR),
    .SLV2_END_ADDR      (SLV2_END_ADDR),
    .SLV3_START_ADDR    (SLV3_START_ADDR),
    .SLV3_END_ADDR      (SLV3_END_ADDR),
    .AWCH_W             (AWCH_W),
    .WCH_W              (WCH_W),
    .BCH_W              (BCH_W),
    .ARCH_W             (ARCH_W),
    .RCH_W              (RCH_W)
    )
    switchs
    (
    .aclk      (aclk),
    .aresetn   (aresetn),
    .srst      (srst),
    .i_awvalid (i_awvalid),
    .i_awready (i_awready),
    .i_awch    (i_awch),
    .i_wvalid  (i_wvalid),
    .i_wready  (i_wready),
    .i_wlast   (i_wlast),
    .i_wch     (i_wch),
    .i_bvalid  (i_bvalid),
    .i_bready  (i_bready),
    .i_bch     (i_bch),
    .i_arvalid (i_arvalid),
    .i_arready (i_arready),
    .i_arch    (i_arch),
    .i_rvalid  (i_rvalid),
    .i_rready  (i_rready),
    .i_rlast   (i_rlast),
    .i_rch     (i_rch),
    .o_awvalid (o_awvalid),
    .o_awready (o_awready),
    .o_awch    (o_awch),
    .o_wvalid  (o_wvalid),
    .o_wready  (o_wready),
    .o_wlast   (o_wlast),
    .o_wch     (o_wch),
    .o_bvalid  (o_bvalid),
    .o_bready  (o_bready),
    .o_bch     (o_bch),
    .o_arvalid (o_arvalid),
    .o_arready (o_arready),
    .o_arch    (o_arch),
    .o_rvalid  (o_rvalid),
    .o_rready  (o_rready),
    .o_rlast   (o_rlast),
    .o_rch     (o_rch)
    );


    ///////////////////////////////////////////////////////////////////////////
    // Slave 0 interface
    ///////////////////////////////////////////////////////////////////////////

    axicb_slv_if
    #(
    .AXI_ADDR_W     (AXI_ADDR_W),
    .AXI_ID_W       (AXI_ID_W),
    .AXI_DATA_W     (AXI_DATA_W),
    .STRB_MODE      (STRB_MODE),
    .AXI_SIGNALING  (AXI_SIGNALING),
    .TIMEOUT_ENABLE (TIMEOUT_ENABLE),
    .AWCH_W         (AWCH_W),
    .WCH_W          (WCH_W),
    .BCH_W          (BCH_W),
    .ARCH_W         (ARCH_W),
    .RCH_W          (RCH_W)
    )
    slv0_if
    (
    .i_aclk       (slv0_aclk),
    .i_aresetn    (slv0_aresetn),
    .i_srst       (slv0_srst),
    .i_awvalid    (o_awvalid[0]),
    .i_awready    (o_awready[0]),
    .i_awch       (o_awch[0*AWCH_W+:AWCH_W]),
    .i_wvalid     (o_wvalid[0]),
    .i_wready     (o_wready[0]),
    .i_wlast      (o_wlast[0]),
    .i_wch        (o_wch[0*WCH_W+:WCH_W]),
    .i_bvalid     (o_bvalid[0]),
    .i_bready     (o_bready[0]),
    .i_bch        (o_bch[0*BCH_W+:BCH_W]),
    .i_arvalid    (o_arvalid[0]),
    .i_arready    (o_arready[0]),
    .i_arch       (o_arch[0*ARCH_W+:ARCH_W]),
    .i_rvalid     (o_rvalid[0]),
    .i_rready     (o_rready[0]),
    .i_rlast      (o_rlast[0]),
    .i_rch        (o_rch[0*RCH_W+:RCH_W]),
    .o_aclk       (slv0_aclk),
    .o_aresetn    (slv0_aresetn),
    .o_srst       (slv0_srst),
    .o_awvalid    (slv0_awvalid),
    .o_awready    (slv0_awready),
    .o_awaddr     (slv0_awaddr),
    .o_awlen      (slv0_awlen),
    .o_awsize     (slv0_awsize),
    .o_awburst    (slv0_awburst),
    .o_awlock     (slv0_awlock),
    .o_awcache    (slv0_awcache),
    .o_awprot     (slv0_awprot),
    .o_awqos      (slv0_awqos),
    .o_awregion   (slv0_awregion),
    .o_awid       (slv0_awid),
    .o_wvalid     (slv0_wvalid),
    .o_wready     (slv0_wready),
    .o_wlast      (slv0_wlast),
    .o_wdata      (slv0_wdata),
    .o_wstrb      (slv0_wstrb),
    .o_bvalid     (slv0_bvalid),
    .o_bready     (slv0_bready),
    .o_bid        (slv0_bid),
    .o_bresp      (slv0_bresp),
    .o_arvalid    (slv0_arvalid),
    .o_arready    (slv0_arready),
    .o_araddr     (slv0_araddr),
    .o_arlen      (slv0_arlen),
    .o_arsize     (slv0_arsize),
    .o_arburst    (slv0_arburst),
    .o_arlock     (slv0_arlock),
    .o_arcache    (slv0_arcache),
    .o_arprot     (slv0_arprot),
    .o_arqos      (slv0_arqos),
    .o_arregion   (slv0_arregion),
    .o_arid       (slv0_arid),
    .o_rvalid     (slv0_rvalid),
    .o_rready     (slv0_rready),
    .o_rid        (slv0_rid),
    .o_rresp      (slv0_rresp),
    .o_rdata      (slv0_rdata),
    .o_rlast      (slv0_rlast)
    );

    ///////////////////////////////////////////////////////////////////////////
    // Slave 1 interface
    ///////////////////////////////////////////////////////////////////////////

    axicb_slv_if
    #(
    .AXI_ADDR_W     (AXI_ADDR_W),
    .AXI_ID_W       (AXI_ID_W),
    .AXI_DATA_W     (AXI_DATA_W),
    .STRB_MODE      (STRB_MODE),
    .AXI_SIGNALING  (AXI_SIGNALING),
    .TIMEOUT_ENABLE (TIMEOUT_ENABLE),
    .AWCH_W         (AWCH_W),
    .WCH_W          (WCH_W),
    .BCH_W          (BCH_W),
    .ARCH_W         (ARCH_W),
    .RCH_W          (RCH_W)
    )
    slv1_if
    (
    .i_aclk       (slv1_aclk),
    .i_aresetn    (slv1_aresetn),
    .i_srst       (slv1_srst),
    .i_awvalid    (o_awvalid[1]),
    .i_awready    (o_awready[1]),
    .i_awch       (o_awch[1*AWCH_W+:AWCH_W]),
    .i_wvalid     (o_wvalid[1]),
    .i_wready     (o_wready[1]),
    .i_wlast      (o_wlast[1]),
    .i_wch        (o_wch[1*WCH_W+:WCH_W]),
    .i_bvalid     (o_bvalid[1]),
    .i_bready     (o_bready[1]),
    .i_bch        (o_bch[1*BCH_W+:BCH_W]),
    .i_arvalid    (o_arvalid[1]),
    .i_arready    (o_arready[1]),
    .i_arch       (o_arch[1*ARCH_W+:ARCH_W]),
    .i_rvalid     (o_rvalid[1]),
    .i_rready     (o_rready[1]),
    .i_rlast      (o_rlast[1]),
    .i_rch        (o_rch[1*RCH_W+:RCH_W]),
    .o_aclk       (slv1_aclk),
    .o_aresetn    (slv1_aresetn),
    .o_srst       (slv1_srst),
    .o_awvalid    (slv1_awvalid),
    .o_awready    (slv1_awready),
    .o_awaddr     (slv1_awaddr),
    .o_awlen      (slv1_awlen),
    .o_awsize     (slv1_awsize),
    .o_awburst    (slv1_awburst),
    .o_awlock     (slv1_awlock),
    .o_awcache    (slv1_awcache),
    .o_awprot     (slv1_awprot),
    .o_awqos      (slv1_awqos),
    .o_awregion   (slv1_awregion),
    .o_awid       (slv1_awid),
    .o_wvalid     (slv1_wvalid),
    .o_wready     (slv1_wready),
    .o_wlast      (slv1_wlast),
    .o_wdata      (slv1_wdata),
    .o_wstrb      (slv1_wstrb),
    .o_bvalid     (slv1_bvalid),
    .o_bready     (slv1_bready),
    .o_bid        (slv1_bid),
    .o_bresp      (slv1_bresp),
    .o_arvalid    (slv1_arvalid),
    .o_arready    (slv1_arready),
    .o_araddr     (slv1_araddr),
    .o_arlen      (slv1_arlen),
    .o_arsize     (slv1_arsize),
    .o_arburst    (slv1_arburst),
    .o_arlock     (slv1_arlock),
    .o_arcache    (slv1_arcache),
    .o_arprot     (slv1_arprot),
    .o_arqos      (slv1_arqos),
    .o_arregion   (slv1_arregion),
    .o_arid       (slv1_arid),
    .o_rvalid     (slv1_rvalid),
    .o_rready     (slv1_rready),
    .o_rid        (slv1_rid),
    .o_rresp      (slv1_rresp),
    .o_rdata      (slv1_rdata),
    .o_rlast      (slv1_rlast)
    );

    ///////////////////////////////////////////////////////////////////////////
    // Slave 2 Interface
    ///////////////////////////////////////////////////////////////////////////

    axicb_slv_if
    #(
    .AXI_ADDR_W     (AXI_ADDR_W),
    .AXI_ID_W       (AXI_ID_W),
    .AXI_DATA_W     (AXI_DATA_W),
    .STRB_MODE      (STRB_MODE),
    .AXI_SIGNALING  (AXI_SIGNALING),
    .TIMEOUT_ENABLE (TIMEOUT_ENABLE),
    .AWCH_W         (AWCH_W),
    .WCH_W          (WCH_W),
    .BCH_W          (BCH_W),
    .ARCH_W         (ARCH_W),
    .RCH_W          (RCH_W)
    )
    slv2_if
    (
    .i_aclk       (slv2_aclk),
    .i_aresetn    (slv2_aresetn),
    .i_srst       (slv2_srst),
    .i_awvalid    (o_awvalid[2]),
    .i_awready    (o_awready[2]),
    .i_awch       (o_awch[2*AWCH_W+:AWCH_W]),
    .i_wvalid     (o_wvalid[2]),
    .i_wready     (o_wready[2]),
    .i_wlast      (o_wlast[2]),
    .i_wch        (o_wch[2*WCH_W+:WCH_W]),
    .i_bvalid     (o_bvalid[2]),
    .i_bready     (o_bready[2]),
    .i_bch        (o_bch[2*BCH_W+:BCH_W]),
    .i_arvalid    (o_arvalid[2]),
    .i_arready    (o_arready[2]),
    .i_arch       (o_arch[2*ARCH_W+:ARCH_W]),
    .i_rvalid     (o_rvalid[2]),
    .i_rready     (o_rready[2]),
    .i_rlast      (o_rlast[2]),
    .i_rch        (o_rch[2*RCH_W+:RCH_W]),
    .o_aclk       (slv2_aclk),
    .o_aresetn    (slv2_aresetn),
    .o_srst       (slv2_srst),
    .o_awvalid    (slv2_awvalid),
    .o_awready    (slv2_awready),
    .o_awaddr     (slv2_awaddr),
    .o_awlen      (slv2_awlen),
    .o_awsize     (slv2_awsize),
    .o_awburst    (slv2_awburst),
    .o_awlock     (slv2_awlock),
    .o_awcache    (slv2_awcache),
    .o_awprot     (slv2_awprot),
    .o_awqos      (slv2_awqos),
    .o_awregion   (slv2_awregion),
    .o_awid       (slv2_awid),
    .o_wvalid     (slv2_wvalid),
    .o_wready     (slv2_wready),
    .o_wlast      (slv2_wlast),
    .o_wdata      (slv2_wdata),
    .o_wstrb      (slv2_wstrb),
    .o_bvalid     (slv2_bvalid),
    .o_bready     (slv2_bready),
    .o_bid        (slv2_bid),
    .o_bresp      (slv2_bresp),
    .o_arvalid    (slv2_arvalid),
    .o_arready    (slv2_arready),
    .o_araddr     (slv2_araddr),
    .o_arlen      (slv2_arlen),
    .o_arsize     (slv2_arsize),
    .o_arburst    (slv2_arburst),
    .o_arlock     (slv2_arlock),
    .o_arcache    (slv2_arcache),
    .o_arprot     (slv2_arprot),
    .o_arqos      (slv2_arqos),
    .o_arregion   (slv2_arregion),
    .o_arid       (slv2_arid),
    .o_rvalid     (slv2_rvalid),
    .o_rready     (slv2_rready),
    .o_rid        (slv2_rid),
    .o_rresp      (slv2_rresp),
    .o_rdata      (slv2_rdata),
    .o_rlast      (slv2_rlast)
    );

    ///////////////////////////////////////////////////////////////////////////
    // Slave 3 Interface
    ///////////////////////////////////////////////////////////////////////////

    axicb_slv_if
    #(
    .AXI_ADDR_W     (AXI_ADDR_W),
    .AXI_ID_W       (AXI_ID_W),
    .AXI_DATA_W     (AXI_DATA_W),
    .STRB_MODE      (STRB_MODE),
    .AXI_SIGNALING  (AXI_SIGNALING),
    .TIMEOUT_ENABLE (TIMEOUT_ENABLE),
    .AWCH_W         (AWCH_W),
    .WCH_W          (WCH_W),
    .BCH_W          (BCH_W),
    .ARCH_W         (ARCH_W),
    .RCH_W          (RCH_W)
    )
    slv3_if
    (
    .i_aclk       (slv3_aclk),
    .i_aresetn    (slv3_aresetn),
    .i_srst       (slv3_srst),
    .i_awvalid    (o_awvalid[3]),
    .i_awready    (o_awready[3]),
    .i_awch       (o_awch[3*AWCH_W+:AWCH_W]),
    .i_wvalid     (o_wvalid[3]),
    .i_wready     (o_wready[3]),
    .i_wlast      (o_wlast[3]),
    .i_wch        (o_wch[3*WCH_W+:WCH_W]),
    .i_bvalid     (o_bvalid[3]),
    .i_bready     (o_bready[3]),
    .i_bch        (o_bch[3*BCH_W+:BCH_W]),
    .i_arvalid    (o_arvalid[3]),
    .i_arready    (o_arready[3]),
    .i_arch       (o_arch[3*ARCH_W+:ARCH_W]),
    .i_rvalid     (o_rvalid[3]),
    .i_rready     (o_rready[3]),
    .i_rlast      (o_rlast[3]),
    .i_rch        (o_rch[3*RCH_W+:RCH_W]),
    .o_aclk       (slv3_aclk),
    .o_aresetn    (slv3_aresetn),
    .o_srst       (slv3_srst),
    .o_awvalid    (slv3_awvalid),
    .o_awready    (slv3_awready),
    .o_awaddr     (slv3_awaddr),
    .o_awlen      (slv3_awlen),
    .o_awsize     (slv3_awsize),
    .o_awburst    (slv3_awburst),
    .o_awlock     (slv3_awlock),
    .o_awcache    (slv3_awcache),
    .o_awprot     (slv3_awprot),
    .o_awqos      (slv3_awqos),
    .o_awregion   (slv3_awregion),
    .o_awid       (slv3_awid),
    .o_wvalid     (slv3_wvalid),
    .o_wready     (slv3_wready),
    .o_wlast      (slv3_wlast),
    .o_wdata      (slv3_wdata),
    .o_wstrb      (slv3_wstrb),
    .o_bvalid     (slv3_bvalid),
    .o_bready     (slv3_bready),
    .o_bid        (slv3_bid),
    .o_bresp      (slv3_bresp),
    .o_arvalid    (slv3_arvalid),
    .o_arready    (slv3_arready),
    .o_araddr     (slv3_araddr),
    .o_arlen      (slv3_arlen),
    .o_arsize     (slv3_arsize),
    .o_arburst    (slv3_arburst),
    .o_arlock     (slv3_arlock),
    .o_arcache    (slv3_arcache),
    .o_arprot     (slv3_arprot),
    .o_arqos      (slv3_arqos),
    .o_arregion   (slv3_arregion),
    .o_arid       (slv3_arid),
    .o_rvalid     (slv3_rvalid),
    .o_rready     (slv3_rready),
    .o_rid        (slv3_rid),
    .o_rresp      (slv3_rresp),
    .o_rdata      (slv3_rdata),
    .o_rlast      (slv3_rlast)
    );

endmodule

`resetall