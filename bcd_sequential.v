/*******************************************************************************

   2進数を10進数に順次変換行います。
	26bit bin → 8桁 Dec

*******************************************************************************/

module bcd_sequential (
    input   wire    SYS_clk,
    input   wire    reset_n,

	input	wire	bin_en,				// 変換要求されたのでbin_in値を取り込み最上位を変換開始します。
	input	wire	[25:0]bin_in,
	input	wire	next_quotient,		// 次の下位の桁を変換開始します。
	output	wire	[3:0]dec_out
   );
	
	reg	[2:0]	digits ;					// 桁数目
	reg	[3:0]	dec_sta ;				// 1桁あたりの足しこむ値 0:idle 8-1:operation
	reg	[3:0]	dec_val ;				// 1桁あたりの数値保持用

	wire 	[25:0]	present_truss8 ;	// 各桁の8値
	reg	[25:0]	present_truss ;
	reg 	[25:0]	present_bin	;		// 現在のbinデータ
	wire 	[25:0]	add_bin ;
	wire 	[3:0]		add_dec ;

	
	// 各桁の最上ビットテーブル
	assign present_truss8 = 
		( digits == 3'h0 ) ? { 26'd8				} :
		( digits == 3'h1 ) ? { 26'd80				} :
		( digits == 3'h2 ) ? { 26'd800  			} :
		( digits == 3'h3 ) ? { 26'd8000			} :
		( digits == 3'h4 ) ? { 26'd80000			} :
		( digits == 3'h5 ) ? { 26'd800000		} :
									{ 26'd8000000		} ;
 
	assign add_bin = present_bin + present_truss ;
	assign add_dec = dec_val | dec_sta ;
	assign dec_out	= dec_val ;

 	always  @(posedge SYS_clk or negedge reset_n)begin
		if(!reset_n) begin
			digits				<= 3'h0 ;
			dec_sta				<= 4'h0 ;
			present_truss		<= 26'h0000000 ;
			dec_val				<= 4'h0 ;
			present_bin			<= 26'h0000000 ;
		end
		else if(bin_en == 1'h1) begin
			// デコード開始要求
			digits				<= 3'h7 ;
			dec_sta				<= 4'h4 ;
			present_truss 		<= 26'd40000000 ;
			dec_val				<= 4'h0 ;
			present_bin			<= 26'h0000000 ;
		end
		else if(next_quotient == 1'h1)begin
			// 次の下位桁
			dec_sta			<= 4'h8 ;
			present_truss 	<= present_truss8 ;
			dec_val			<= 4'h0 ;
		end
		else if(dec_sta != 4'h0)begin
			if(add_bin <= bin_in) begin
				present_bin		<= add_bin ;
				dec_val 		<= add_dec ;
			end
			if((dec_sta == 4'h1) && (digits != 3'h0)) begin
				// 1桁終了
				// 次の下位桁をあらかじめセット
				digits	<= digits - 3'h1 ;
			end
			dec_sta			<= { 1'h0 ,dec_sta[3:1] 			};
			present_truss	<= { 1'h0 ,present_truss[25:1] 	};
		end
	end
		 
endmodule

