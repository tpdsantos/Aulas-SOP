
set PRODS ;

param CRUDE_COST          >= 0 ;
param NEEDS     { PRODS } >= 0 ;
param PRICE     { PRODS } >= 0 ;

########################################

var prods {p in PRODS} >= 0 , <= NEEDS[p]/30 ;


##### BALANÇO COLUNA DE DESTILAÇÃO #####

set DEST_OUT ;

param MAX_DEST                  >= 0         ;
param OP_COST_DEST              >= 0         ;
param DEST_REND    { DEST_OUT } >= 0, <= 100 ;

var crude  >= 0 , <= MAX_DEST ;
var dest_out {do in DEST_OUT}  = crude * DEST_REND[do] ;


##### BALANÇO UNIDADE DE CRACKING #####

set CRACK_IN  ;
set CRACK_OUT ;

param OP_COST_CRACK { CRACK_IN  } >= 0 ;
param CRACK_MAX     { CRACK_IN  } >= 0 ;
param CRACK_REND    { CRACK_OUT } >= 0 ;

var crack_in {ci in CRACK_IN } >= 0 , <= CRACK_MAX[ci] ;
var crack_out {co in CRACK_OUT} = sum {ci in CRACK_IN} ( crack_in[ci] ) * CRACK_REND[co] ;


##### BALANÇO AO BLENDING DE FUEL ÓLEO #####

set BLEND_IN ;

var blend_in { BLEND_IN } >= 0 ;

s.t. fuel_oil : prods['Fuel'] = sum {bi in BLEND_IN} ( blend_in[bi] ) ;

s.t. blend_res {iv in {'Res'}}: blend_in[iv] = dest_out[iv] ;


##### BALANÇO NAFTA #####

var inter_nafta >= 0 ;

s.t. nafta_mass_balance {iv in {'Naf'}}: dest_out[iv] = inter_nafta + prods[iv] ;


##### BALANÇO GASOLINA #####

s.t. gas_mass_balance {iv in {'Gas'}} : inter_nafta + crack_out[iv] = prods[iv] ;
s.t. nafta_restraint  {iv in {'Gas'}} : inter_nafta = crack_out[iv] ;


##### BALANÇO DESTILADO MÉDIO #####

var inter_dm >= 0 ;

s.t. dm_mass_balance {iv in {'DM'}} : dest_out[iv] = blend_in[iv] + inter_dm ;


##### BALANÇO GASÓLEO #####

var inter_diesel >= 0 ;

s.t. diesel_mass_balance {iv in {'Diesel'}} : crack_out[iv] = blend_in[iv] + inter_diesel ;


##### BALANÇO ÓLEO COMBUSTÍVEL #####

s.t. oil_mass_balance {iv in {'Oil'}} : prods[iv] = inter_dm + inter_diesel ;
s.t. ratio_restraint  : inter_dm = 0.75 * (inter_dm+inter_diesel) ;


##### BALANÇO JET FUEL #####

s.t. jet_mass_balance {iv in {'Jet'}} : prods[iv] = dest_out[iv] ;


##### DETERMINAÇÃO DE VALORES FINANCEIROS #####

var costs = CRUDE_COST * crude
          + OP_COST_DEST * crude
          + sum {ci in CRACK_IN} ( crack_in[ci] * OP_COST_CRACK[ci] )
          ;

var sales = sum {p in PRODS} ( PRICE[p] * prods[p] ) ;

maximize profit : sales - costs ;

##############################################

data ;

set PRODS     := Gas Naf Jet Oil Fuel ;

param CRUDE_COST := 7.5 ;

param :        NEEDS , PRICE :=
	Gas    81000    18.5
        Naf    33000     8.0
        Jet    69000    12.5
        Oil    51000    14.5
        Fuel  285000     6.0  ;

set DEST_OUT  := Naf Jet DM DP Res ;
param MAX_DEST := 15000 ;
param OP_COST_DEST := 0.5 ;
param DEST_REND := Naf 0.13
                   Jet 0.15
                   DM  0.22
                   DP  0.20
                   Res 0.30 ;


set CRACK_IN  := DP ;
set CRACK_OUT := Gas Diesel Waste ;

param :     OP_COST_CRACK , CRACK_MAX :=
	DP     1.5           2500      ;

param CRACK_REND := Gas    0.40
                    Diesel 0.55
                    Waste  0.05 ;

set BLEND_IN := Res DP DM Diesel ;

##############################################

option substout 1 ;
option show_stats 1 ;
option solver "/home/tsantos/SOFTWARES/ampl-demo/cplex" ;
solve ;

display profit ;
display {p in PRODS} prods[p] ;