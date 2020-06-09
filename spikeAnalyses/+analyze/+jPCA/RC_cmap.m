function [cm,iUnsuccessful,iSuccessful] = RC_cmap()
%RC_cmap Returns specific color map for RC project success vs fail trials
%
% cm = analyze.jPCA.RC_cmap();
% [cm,iUnsuccessful,iSuccessful] = analyze.jPCA.RC_cmap();
%
% Inputs
%  none
%
% Output
%  cm   - 256x3 array where top rows are red colors corresponding to
%           unsuccessful trials and bottom rows are blue colors
%           corresponding to successful trials.
%
%  [iUnsuccessful,iSuccessful] - Indices corresponding to rows for
%                                   unsuccessful, successful colors,
%                                   respectively.
%
% See Also: analyze.jPCA.blankFigure

cm = [1,0.00196078442968428,0.00196078442968428;1,0.00994530320167542,0.00994530320167542;1,0.0179298222064972,0.0179298222064972;1,0.0259143412113190,0.0259143412113190;1,0.0338988602161408,0.0338988602161408;1,0.0418833792209625,0.0418833792209625;1,0.0498678982257843,0.0498678982257843;1,0.0578524172306061,0.0578524172306061;1,0.0658369362354279,0.0658369362354279;1,0.0738214552402496,0.0738214552402496;1,0.0818059742450714,0.0818059742450714;1,0.0897904932498932,0.0897904932498932;1,0.0977750122547150,0.0977750122547150;1,0.105759531259537,0.105759531259537;1,0.113744050264359,0.113744050264359;1,0.121728569269180,0.121728569269180;1,0.129713088274002,0.129713088274002;1,0.137697607278824,0.137697607278824;1,0.145682126283646,0.145682126283646;1,0.153666645288467,0.153666645288467;1,0.161651164293289,0.161651164293289;1,0.169635683298111,0.169635683298111;1,0.177620202302933,0.177620202302933;1,0.185604721307755,0.185604721307755;1,0.193589240312576,0.193589240312576;1,0.201573759317398,0.201573759317398;1,0.209558278322220,0.209558278322220;1,0.217542797327042,0.217542797327042;1,0.225527316331863,0.225527316331863;1,0.233511835336685,0.233511835336685;1,0.241496354341507,0.241496354341507;1,0.249480873346329,0.249480873346329;1,0.257465392351151,0.257465392351151;1,0.265449911355972,0.265449911355972;1,0.273434430360794,0.273434430360794;1,0.281418949365616,0.281418949365616;1,0.289403468370438,0.289403468370438;1,0.297387987375259,0.297387987375259;1,0.305372506380081,0.305372506380081;1,0.313357025384903,0.313357025384903;1,0.321341544389725,0.321341544389725;1,0.329326063394547,0.329326063394547;1,0.337310582399368,0.337310582399368;1,0.345295101404190,0.345295101404190;1,0.353279620409012,0.353279620409012;1,0.361264139413834,0.361264139413834;1,0.369248658418655,0.369248658418655;1,0.377233177423477,0.377233177423477;1,0.385217696428299,0.385217696428299;1,0.393202215433121,0.393202215433121;1,0.401186734437943,0.401186734437943;1,0.409171253442764,0.409171253442764;1,0.417155772447586,0.417155772447586;1,0.425140291452408,0.425140291452408;1,0.433124810457230,0.433124810457230;1,0.441109329462051,0.441109329462051;1,0.449093848466873,0.449093848466873;1,0.457078367471695,0.457078367471695;1,0.465062886476517,0.465062886476517;1,0.473047405481339,0.473047405481339;1,0.481031924486160,0.481031924486160;1,0.489016443490982,0.489016443490982;1,0.497000962495804,0.497000962495804;1,0.504985511302948,0.504985511302948;1,0.512970030307770,0.512970030307770;1,0.520954549312592,0.520954549312592;1,0.528939068317413,0.528939068317413;1,0.536923587322235,0.536923587322235;1,0.544908106327057,0.544908106327057;1,0.552892625331879,0.552892625331879;1,0.560877144336700,0.560877144336700;1,0.568861663341522,0.568861663341522;1,0.576846182346344,0.576846182346344;1,0.584830701351166,0.584830701351166;1,0.592815220355988,0.592815220355988;1,0.600799739360809,0.600799739360809;1,0.608784258365631,0.608784258365631;1,0.616768777370453,0.616768777370453;1,0.624753296375275,0.624753296375275;1,0.632737815380096,0.632737815380096;1,0.640722334384918,0.640722334384918;1,0.648706853389740,0.648706853389740;1,0.656691372394562,0.656691372394562;1,0.664675891399384,0.664675891399384;1,0.672660410404205,0.672660410404205;1,0.680644929409027,0.680644929409027;1,0.688629448413849,0.688629448413849;1,0.696613967418671,0.696613967418671;1,0.704598486423492,0.704598486423492;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.712583005428314,0.712583005428314;1,0.748755216598511,0.748755216598511;1,0.784927427768707,0.784927427768707;1,0.821099638938904,0.821099638938904;1,0.857271909713745,0.857271909713745;1,0.893444120883942,0.893444120883942;1,0.929616332054138,0.929616332054138;1,0.965788543224335,0.965788543224335;1,1,1;0.989832997322083,0.989832997322083,0.989832997322083;0.977705180644989,0.977705180644989,0.977705180644989;0.965577363967896,0.965577363967896,0.965577363967896;0.953449547290802,0.953449547290802,0.953449547290802;0.941321730613709,0.941321730613709,0.941321730613709;0.929193913936615,0.929193913936615,0.929193913936615;0.917066097259522,0.917066097259522,0.917066097259522;0.904938280582428,0.904938280582428,0.904938280582428;0.892810463905335,0.892810463905335,0.892810463905335;0.595860540866852,0.595860540866852,0.595860540866852;0.298910677433014,0.298910677433014,0.298910677433014;0.00196078442968428,0.00196078442968428,0.00196078442968428;0.00708351144567132,0.00706006027758122,0.00706028752028942;0.0122062386944890,0.0121124349534512,0.0121142519637942;0.0173289645463228,0.0171179063618183,0.0171240400522947;0.0224516931921244,0.0220764782279730,0.0220910143107176;0.0275744199752808,0.0269881468266249,0.0270165372639895;0.0326971448957920,0.0318529121577740,0.0319019742310047;0.0378198735415936,0.0366707779467106,0.0367486849427223;0.198510020971298,0.192150071263313,0.192590028047562;0.359200179576874,0.347528636455536,0.348352134227753;0.519890308380127,0.502806544303894,0.504035413265228;0.682541310787201,0.659944474697113,0.661601126194000;0.718032360076904,0.694199621677399,0.695954203605652;0.753523409366608,0.728449106216431,0.730302751064301;0.789014458656311,0.762692868709564,0.764646768569946;0.824505507946014,0.796930968761444,0.798986315727234;0.859996557235718,0.831163346767426,0.833321332931519;0.895487606525421,0.865390062332153,0.867651879787445;0.930978655815125,0.899611055850983,0.901977896690369;0.966469705104828,0.933826327323914,0.936299443244934;1,0.968035936355591,0.970616519451141;0.0760390609502792,0.622776091098785,0.997285127639771;0.0717113241553307,0.616148531436920,0.988687813282013;0.0693697258830071,0.611489832401276,0.982051312923431;0.0670534893870354,0.606839299201965,0.975414812564850;0.0647626072168350,0.602196812629700,0.968778312206268;0.0624970868229866,0.597562372684479,0.962141811847687;0.0602569207549095,0.592935979366303,0.955505311489105;0.0580421164631844,0.588317632675171,0.948868811130524;0.0558526664972305,0.583707213401794,0.942232310771942;0.0536885783076286,0.579104840755463,0.935595810413361;0.0515498444437981,0.574510395526886,0.928959310054779;0.0494364723563194,0.569923937320709,0.922322809696198;0.0473484583199024,0.565345346927643,0.915686309337616;0.0452858023345470,0.560774683952332,0.909049808979034;0.0432485006749630,0.556211888790131,0.902413308620453;0.0412365607917309,0.551656961441040,0.895776808261871;0.0392499789595604,0.547109901905060,0.889140307903290;0.0372887551784515,0.542570650577545,0.882503807544708;0.0353528894484043,0.538039207458496,0.875867307186127;0.0334423817694187,0.533515572547913,0.869230806827545;0.0315572321414948,0.528999686241150,0.862594306468964;0.0296974405646324,0.524491548538208,0.855957806110382;0.0278630070388317,0.519991099834442,0.849321305751801;0.0260539315640926,0.515498399734497,0.842684805393219;0.0242702141404152,0.511013388633728,0.836048305034638;0.0225118547677994,0.506536006927490,0.829411804676056;0.0207788553088903,0.502066314220429,0.822775304317474;0.0190712120383978,0.497604280710220,0.816138803958893;0.0173889286816120,0.493149816989899,0.809502303600311;0.0157320015132427,0.488702952861786,0.802865803241730;0.0141004342585802,0.484263658523560,0.796229302883148;0.0124942241236568,0.479831904172897,0.789592802524567;0.0109133720397949,0.475407719612122,0.782956302165985;0.00935787893831730,0.470991015434265,0.776319801807404;0.00782774388790131,0.466581821441650,0.769683301448822;0.00632296642288566,0.462180107831955,0.763046801090241;0.00484354747459292,0.457785844802856,0.756410300731659;0.00338948681019247,0.453399032354355,0.749773800373077;0.00196078442968428,0.449019610881805,0.743137300014496;0.00196078442968428,0.444506615400314,0.747119188308716;0.00196078442968428,0.439919710159302,0.751101076602936;0.00196078442968428,0.435258924961090,0.755082964897156;0.00196078442968428,0.430524230003357,0.759064853191376;0.00196078442968428,0.425715625286102,0.763046801090241;0.00196078442968428,0.420833110809326,0.767028689384460;0.00196078442968428,0.415876716375351,0.771010577678680;0.00196078442968428,0.410846412181854,0.774992465972900;0.00196078442968428,0.405742198228836,0.778974354267120;0.00196078442968428,0.400564104318619,0.782956302165985;0.00196078442968428,0.395312070846558,0.786938190460205;0.00196078442968428,0.389986187219620,0.790920078754425;0.00196078442968428,0.384586364030838,0.794901967048645;0.00196078442968428,0.379112660884857,0.798883855342865;0.00196078442968428,0.373565047979355,0.802865803241730;0.00196078442968428,0.367943525314331,0.806847691535950;0.00196078442968428,0.362248122692108,0.810829579830170;0.00196078442968428,0.356478810310364,0.814811468124390;0.00196078442968428,0.350635588169098,0.818793356418610;0.00196078442968428,0.344718486070633,0.822775304317474;0.00196078442968428,0.338727474212647,0.826757192611694;0.00196078442968428,0.332662552595139,0.830739080905914;0.00196078442968428,0.326523721218109,0.834720969200134;0.00196078442968428,0.320311009883881,0.838702857494354;0.00196078442968428,0.314024388790131,0.842684805393219;0.00196078442968428,0.307663857936859,0.846666693687439;0.00196078442968428,0.301229447126389,0.850648581981659;0.00196078442968428,0.294721126556397,0.854630470275879;0.00196078442968428,0.288138896226883,0.858612358570099;0.00196078442968428,0.281482756137848,0.862594306468964;0.00196078442968428,0.274752736091614,0.866576194763184;0.00196078442968428,0.267948806285858,0.870558083057404;0.00196078442968428,0.261070996522903,0.874539971351624;0.00196078442968428,0.254119247198105,0.878521859645844;0.00196078442968428,0.247093632817268,0.882503807544708;0.00196078442968428,0.239994093775749,0.886485695838928;0.00196078442968428,0.232820659875870,0.890467584133148;0.00196078442968428,0.225573331117630,0.894449472427368;0.00196078442968428,0.218252092599869,0.898431360721588;0.00196078442968428,0.210856959223747,0.902413308620453;0.00196078442968428,0.203387930989265,0.906395196914673;0.00196078442968428,0.195844992995262,0.910377085208893;0.00196078442968428,0.188228160142899,0.914358973503113;0.00196078442968428,0.180537417531014,0.918340861797333;0.00196078442968428,0.172772780060768,0.922322809696198;0.00196078442968428,0.164934232831001,0.926304697990418;0.00196078442968428,0.157021790742874,0.930286586284638;0.00196078442968428,0.149035453796387,0.934268474578857;0.00196078442968428,0.140975207090378,0.938250362873077;0.00196078442968428,0.132841065526009,0.942232310771942;0.00196078442968428,0.124633021652699,0.946214199066162;0.00196078442968428,0.116351075470448,0.950196087360382;0.00196078442968428,0.107995226979256,0.954177975654602;0.00196078442968428,0.0995654761791229,0.958159863948822;0.00196078442968428,0.0910618305206299,0.962141811847687;0.00196078442968428,0.0824842751026154,0.966123700141907;0.00196078442968428,0.0738328248262405,0.970105588436127;0.00196078442968428,0.0651074722409248,0.974087476730347;0.00196078442968428,0.0563082210719585,0.978069365024567;0.00196078442968428,0.0474350675940514,0.982051312923431;0.00196078442968428,0.0384880118072033,0.986033201217651;0.00196078442968428,0.0294670574367046,0.990015089511871;0.00196078442968428,0.0203722007572651,0.993996977806091;0.00196078442968428,0.0112034427002072,0.997978866100311;0.00196078442968428,0.00196078442968428,1];
iUnsuccessful = 1:64;
iSuccessful = 192:256;
end