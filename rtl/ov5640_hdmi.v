//****************************************Copyright (c)***********************************//
//ԭ�Ӹ����߽�ѧƽ̨��www.yuanzige.com
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡZYNQ & FPGA & STM32 & LINUX���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ov5640_hdmi
// Last modified Date:  2020/05/04 9:19:08
// Last Version:        V1.0
// Descriptions:        OV5640����ͷHDMI��ʾ
//                      
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2019/05/04 9:19:08
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ov5640_hdmi(    
    input                 sys_rst_n    ,  //ϵͳ��λ���͵�ƽ��Ч
    input                 locked       ,  //PLL����ź� (from external unified PLL)
    // Clock inputs from external unified PLL
    input                 clk_200m     ,  //200MHz DDR3�ο�ʱ��
    input                 clk_50m      ,  //50MHz����ͷ����ʱ��
    input                 pixel_clk    ,  //HDMIͼ��ʱ��
    input                 pixel_clk_5x ,  //HDMI����ʱ�� (5x)
    //����ͷ�ӿ�                       
    input                 cam_pclk     ,  //cmos ��������ʱ��
    input                 cam_vsync    ,  //cmos ��ͬ���ź�
    input                 cam_href     ,  //cmos ��ͬ���ź�
    input   [7:0]         cam_data     ,  //cmos ����
    output                cam_rst_n    ,  //cmos ��λ�źţ��͵�ƽ��Ч
    output                cam_pwdn     ,  //��Դ����ģʽѡ�� 0������ģʽ 1����Դ����ģʽ
    output                cam_scl      ,  //cmos SCCB_SCL��
    inout                 cam_sda      ,  //cmos SCCB_SDA��       
    // DDR3                            
    inout   [15:0]        ddr3_dq      ,  //DDR3 ����
    inout   [1:0]         ddr3_dqs_n   ,  //DDR3 dqs��
    inout   [1:0]         ddr3_dqs_p   ,  //DDR3 dqs��  
    output  [13:0]        ddr3_addr    ,  //DDR3 ��ַ   
    output  [2:0]         ddr3_ba      ,  //DDR3 banck ѡ��
    output                ddr3_ras_n   ,  //DDR3 ��ѡ��
    output                ddr3_cas_n   ,  //DDR3 ��ѡ��
    output                ddr3_we_n    ,  //DDR3 ��дѡ��
    output                ddr3_reset_n ,  //DDR3 ��λ
    output  [0:0]         ddr3_ck_p    ,  //DDR3 ʱ����
    output  [0:0]         ddr3_ck_n    ,  //DDR3 ʱ�Ӹ�
    output  [0:0]         ddr3_cke     ,  //DDR3 ʱ��ʹ��
    output  [0:0]         ddr3_cs_n    ,  //DDR3 Ƭѡ
    output  [1:0]         ddr3_dm      ,  //DDR3_dm
    output  [0:0]         ddr3_odt     ,  //DDR3_odt									                            
    //hdmi�ӿ�                           
    output                tmds_clk_p   ,  // TMDS ʱ��ͨ��
    output                tmds_clk_n   ,
    output  [2:0]         tmds_data_p  ,  // TMDS ����ͨ��
    output  [2:0]         tmds_data_n  ,
    output                tmds_oen        // TMDS ���ʹ��
    );     

//parameter define                                
parameter  V_CMOS_DISP = 11'd768;                  //CMOS�ֱ���--��
parameter  H_CMOS_DISP = 11'd1024;                 //CMOS�ֱ���--��	
parameter  TOTAL_H_PIXEL = H_CMOS_DISP + 12'd1216; 
parameter  TOTAL_V_PIXEL = V_CMOS_DISP + 12'd504;    										   
							   
//wire define                          
wire         rst_n                     ;  //ȫ�ָ�λ 								           
wire         cam_init_done             ;  //����ͷ��ʼ�����							    
wire         wr_en                     ;  //DDR3������ģ��дʹ��
wire  [15:0] wrdata                    ;  //DDR3������ģ��д����
wire         rdata_req                 ;  //DDR3������ģ���ʹ��
wire  [15:0] rddata                    ;  //DDR3������ģ�������
wire         rd_vsync                  ;  //���Դ�����ź�
wire         cmos_frame_valid          ;  //������Чʹ���ź�
wire         init_calib_complete       ;  //DDR3��ʼ�����init_calib_complete
wire         sys_init_done             ;  //ϵͳ��ʼ�����(DDR��ʼ��+����ͷ��ʼ��)
wire         cmos_frame_vsync          ;  //���֡��Ч��ͬ���ź�
wire         cmos_frame_href           ;  //���֡��Ч��ͬ���ź� 
wire  [27:0] app_addr_rd_min           ;  //��DDR3����ʼ��ַ
wire  [27:0] app_addr_rd_max           ;  //��DDR3�Ľ�����ַ
wire  [7:0]  rd_bust_len               ;  //��DDR3�ж�����ʱ��ͻ������
wire  [27:0] app_addr_wr_min           ;  //дDDR3����ʼ��ַ
wire  [27:0] app_addr_wr_max           ;  //дDDR3�Ľ�����ַ
wire  [7:0]  wr_bust_len               ;  //��DDR3��д����ʱ��ͻ������ 

//*****************************************************
//**                    main code
//*****************************************************

//��ʱ�������������λ�����ź�
assign  rst_n = sys_rst_n & locked;

//ϵͳ��ʼ����ɣ�DDR3��ʼ�����
assign  sys_init_done = init_calib_complete;

 //ov5640 ����
ov5640_dri u_ov5640_dri(
    .clk               (clk_50m),
    .rst_n             (rst_n),

    .cam_pclk          (cam_pclk ),
    .cam_vsync         (cam_vsync),
    .cam_href          (cam_href ),
    .cam_data          (cam_data ),
    .cam_rst_n         (cam_rst_n),
    .cam_pwdn          (cam_pwdn ),
    .cam_scl           (cam_scl  ),
    .cam_sda           (cam_sda  ),
    
    .capture_start     (init_calib_complete),
    .cmos_h_pixel      (H_CMOS_DISP),
    .cmos_v_pixel      (V_CMOS_DISP),
    .total_h_pixel     (TOTAL_H_PIXEL),
    .total_v_pixel     (TOTAL_V_PIXEL),
    .cmos_frame_vsync  (cmos_frame_vsync),
    .cmos_frame_href   (),
    .cmos_frame_valid  (cmos_frame_valid),
    .cmos_frame_data   (wrdata)
    );   

ddr3_top u_ddr3_top (
    .sys_clk_i           (clk_200m),                  //MIG IP������ʱ�� 
    .clk_ref_i           (clk_200m),                  //ddr3�ο�ʱ��    
    .rst_n               (rst_n),                     //��λ,����Ч
    .init_calib_complete (init_calib_complete),       //ddr3��ʼ������ź�    
    //ddr3�ӿ��ź�       
    .app_addr_rd_min     (28'd0),                     //��DDR3����ʼ��ַ
    .app_addr_rd_max     (V_CMOS_DISP*H_CMOS_DISP),   //��DDR3�Ľ�����ַ
    .rd_bust_len         (H_CMOS_DISP[10:3]),         //��DDR3�ж�����ʱ��ͻ������
    .app_addr_wr_min     (28'd0),                     //дDDR3����ʼ��ַ
    .app_addr_wr_max     (V_CMOS_DISP*H_CMOS_DISP),   //дDDR3�Ľ�����ַ
    .wr_bust_len         (H_CMOS_DISP[10:3]),         //��DDR3��д����ʱ��ͻ������   
    // DDR3 IO�ӿ�              
    .ddr3_dq             (ddr3_dq),                   //DDR3 ����
    .ddr3_dqs_n          (ddr3_dqs_n),                //DDR3 dqs��
    .ddr3_dqs_p          (ddr3_dqs_p),                //DDR3 dqs��  
    .ddr3_addr           (ddr3_addr),                 //DDR3 ��ַ   
    .ddr3_ba             (ddr3_ba),                   //DDR3 banck ѡ��
    .ddr3_ras_n          (ddr3_ras_n),                //DDR3 ��ѡ��
    .ddr3_cas_n          (ddr3_cas_n),                //DDR3 ��ѡ��
    .ddr3_we_n           (ddr3_we_n),                 //DDR3 ��дѡ��
    .ddr3_reset_n        (ddr3_reset_n),              //DDR3 ��λ
    .ddr3_ck_p           (ddr3_ck_p),                 //DDR3 ʱ����
    .ddr3_ck_n           (ddr3_ck_n),                 //DDR3 ʱ�Ӹ�  
    .ddr3_cke            (ddr3_cke),                  //DDR3 ʱ��ʹ��
    .ddr3_cs_n           (ddr3_cs_n),                 //DDR3 Ƭѡ
    .ddr3_dm             (ddr3_dm),                   //DDR3_dm
    .ddr3_odt            (ddr3_odt),                  //DDR3_odt
    //�û�                                            
    .ddr3_read_valid     (1'b1),                      //DDR3 ��ʹ��
    .ddr3_pingpang_en    (1'b1),                      //DDR3 ƹ�Ҳ���ʹ��
    .wr_clk              (cam_pclk),                  //дʱ��
    .wr_load             (cmos_frame_vsync),          //����Դ�����ź�   
	.wr_en               (cmos_frame_valid),          //������Чʹ���ź�
    .wrdata              (wrdata),                    //��Ч���� 
    .rd_clk              (pixel_clk),                 //��ʱ�� 
    .rd_load             (rd_vsync),                  //���Դ�����ź�    
    .rddata              (rddata),                    //rfifo�������
    .rdata_req           (rdata_req)                  //������������   
     );                    

//HDMI������ʾģ��
// Note: PLL removed - all clocks now come from external unified PLL    
hdmi_top u_hdmi_top(
    .pixel_clk            (pixel_clk),
    .pixel_clk_5x         (pixel_clk_5x),    
    .sys_rst_n            (sys_init_done & rst_n),
    //hdmi�ӿ�                   
    .tmds_clk_p           (tmds_clk_p   ),   // TMDS ʱ��ͨ��
    .tmds_clk_n           (tmds_clk_n   ),
    .tmds_data_p          (tmds_data_p  ),   // TMDS ����ͨ��
    .tmds_data_n          (tmds_data_n  ),
    .tmds_oen             (tmds_oen     ),   // TMDS ���ʹ��
    //�û��ӿ� 
    .video_vs             (rd_vsync     ),   //HDMI���ź�  
    .pixel_xpos           (),
    .pixel_ypos           (),      
    .data_in              (rddata),          //�������� 
    .data_req             (rdata_req)        //������������   
);   

endmodule