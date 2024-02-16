# Copyright (c) 2020-2024, Bank of Canada
# All rights reserved.

using Test
using TimeSeriesEcon
using Suppressor
using OrderedCollections

# https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=2010000101
mvsales = [14026,18340,20896,21421,15978,17416,19623,22482,21567,24160,27260,31793,33468,33468,36070,36341,31306,43740,44867,40531,33235,26938,25555,40688,37690,37710,43431,33001,27616,37720,41741,44097,43031,25386,32984,52640,60856,59577,57546,59295,37086,56657,61594,40301,44803,55003,59803,70817,74109,82114,93811,89343,67981,83062,74479,71366,63782,76648,101020,116907,114159,92670,83750,74539,55081,70836,58049,55629,50873,52966,66166,85656,102928,123352,106320,94224,66350,78771,83880,78592,63412,75031,96516,124814,140674,133302,118005,106789,73145,75755,82769,71750,63921,59204,76864,116961,121793,113534,100391,85919,69868,71881,53389,55917,63797,57509,70046,92435,143719,159987,146006,126378,111270,85961,93986,83251,85342,63791,85975,128272,169259,189177,169710,147728,120925,98092,97733,90823,93890,101295,98952,138462,164918,163236,135534,123716,109997,95692,76094,77947,83088,94358,95032,125078,158422,146776,136284,123589,93153,81790,101647,98179,111158,103828,114828,150070,179815,169327,173526,130971,114541,94969,113022,107519,87752,101630,122915,152950,172305,174514,173781,116751,105641,93835,119567,126420,114518,101581,110050,136687,155335,176826,159450,134574,110324,86651,115575,150105,114250,133180,118108,173329,186628,222959,182954,139128,106974,70550,149172,154452,145482,137125,143862,175270,229596,229994,212119,154817,110362,100826,187701,203618,176749,172961,177034,228289,255588,261534,236405,190015,139231,144514,197896,179470,154865,171132,178737,251435,288616,294183,284237,214519,186539,142779,228804,254410,243938,196285,206228,323969,268718,257376,267288,205565,210085,178182,232026,243176,235693,188347,187814,280274,268366,333304,309820,195671,190084,181575,229939,223692,209480,209047,213980,283693,274701,337345,295103,257824,224387,197146,305942,270435,246186,226767,254431,316694,339310,339274,319481,249978,197795,264272,309598,278919,226360,183331,188936,264384,288779,289895,305478,234446,188705,211277,283451,205479,168169,153062,205214,316591,365544,381388,359354,273128,219354,297968,374645,330785,276018,232850,271410,369016,383121,512031,451966,324903,292663,307104,453885,401762,312348,322342,366535,568805,554044,554222,550892,382970,381922,367073,523759,458179,339631,405002,423620,498786,581825,701937,592245,529880,495023,407736,523639,408324,348968,371997,480243,545762,655550,714015,741305,623215,557131,506181,765010,649542,651057,420554,503246,686400,795913,820201,832160,634717,568959,437967,844207,626712,583052,598258,609386,807531,788144,875594,854228,681548,684133,555836,847430,704168,539637,575773,660336,830586,931013,1042458,1027501,812087,761198,774534,925044,727857,581139,675053,796882,1097470,1053106,1213227,1161160,1070845,869164,830222,1145045,876048,693760,768414,885916,1083029,1116821,1009042,1005136,1003537,912937,846855,1134927,882178,729812,772176,856473,1214141,1312656,1207138,1194488,967396,851933,877823,903222,1066638,694311,583665,746980,941897,999456,1011831,1093600,679446,752619,786239,733560,765224,729454,580247,680991,1138305,1244840,1187227,1251451,941425,1002558,906721,1164248,1199996,898317,923557,1120598,1528335,1471449,1683172,1620562,1260598,1186586,1013207,1532192,1266907,1072597,1140754,1214675,1741819,2030177,2007142,2058585,1610115,1598249,1454694,1884221,1696384,1453304,1341418,1539214,1829544,2311485,2220368,2046566,1976171,1736781,1709660,1931456,1601001,1597886,1286498,1567720,2248091,2591424,2338435,2602299,1937215,1990052,1838712,2267914,2007771,1795621,1526332,1756302,2705521,2694627,2863769,2546215,2133750,2218823,2017577,2284684,2154222,1963505,1546441,1798941,2430460,3073601,3122309,2565379,1990790,2189513,2115091,2300071,2112901,1713881,1716818,1688292,2629595,2548948,2761967,2555167,2066940,2015164,1747583,2029481,1720832,1407964,1438359,1432005,1914665,2458908,2554881,2510073,2172463,1714919,1830044,1758944,1651890,1418475,1503355,1577017,2089908,2377625,2351046,2352791,2075113,1869378,1996506,1871867,1741878,1677971,1362140,1394538,2308600,2485723,2582940,2414027,2185670,1966377,1962682,2041452,2058835,1867375,1647772,1747093,2641147,2744338,2934499,2925984,2255666,2096987,2251448,2377165,2262384,2009312,1770967,1869733,2669870,2478218,3004407,2908311,2212189,2354999,2396467,2299947,2179178,2024520,1897218,2094659,2754785,2717501,3238183,3142366,2594296,2391307,2475602,2894859,2620513,2664488,2151641,2456273,3342741,3636853,3949541,3665600,3261313,2994791,3114374,3371864,3201748,3839485,2179285,2435964,3596739,3900578,4361440,4183374,3325536,3057786,3569508,3220716,3153269,3271582,2567669,2721576,4242978,4145962,4340828,4458515,3704818,3652492,4065544,3644129,3702038,4071365,2843715,3014977,4632012,4369507,4910387,4723138,3696472,4115554,4268641,3388700,3526918,3440493,2859254,2657565,4231569,4381553,4854163,4693081,3750259,3994642,3716896,3697632,3947242,4102396,3412178,3174004,4504327,4945277,5463686,5034008,4195497,4517781,4362089,4239363,3969183,4410106,2941847,3276166,4619716,4671934,5551388,4596710,4570411,4452716,4487201,3996557,3678577,3650085,2711635,3005344,4674152,4889605,5029987,4812540,4256526,4247689,4204154,4012022,3938961,3856608,2687357,3481340,4750643,5287013,5142342,5325761,4981923,4636671,4107993,3823755,4076656,4009693,2943630,3315853,5042821,5047812,5505594,5190119,4593190,5003098,4551778,4117566,4230872,4423928,3133627,3315696,5011240,5386679,5854394,5348247,4471995,4906210,4192666,3989014,3907470,4159628,3386322,3560284,4775620,5502356,5583623,4935721,4603855,4484657,4196301,3955760,3392779,3188261,2474417,2555416,4023591,4414203,4824893,4461372,4372313,4365353,4166515,4036810,3437215,3805490,2834682,3307185,4817510,4974619,4990170,5090394,4853046,4521798,4549860,4216887,4054432,4105026,2965868,3359312,5159286,5325409,5051223,5541638,4693564,4780998,4669021,4437146,4167963,3974503,3348298,3679112,5396923,5271661,5909814,5693440,4972339,5008633,4828816,4638168,4331407,3866028,3417225,3642985,5446411,5991964,6354237,5905953,5439723,5419180,5212522,5175550,4718693,4166792,3461575,3779018,5682849,6278892,6884962,6266851,6277118,6021329,6094943,5681354,5074899,5009469,3729812,4118142,5967542,6910768,7189418,6667610,6512342,6409757,6570649,6084201,5478891,5126074,4295419,4728596,6745037,7570371,7379863,7258509,6654406,6691685,6942118,6121957,6467708,5268834,4538110,5022160,7537573,7925441,8590484,8299645,7295374,7488038,7694331,6915797,6764403,5530452,5006244,5354688,8040083,8249951,9281703,8634033,7365887,7394498,7628266,7097044,6766437,5400236,4856206,5360981,8172306,8126000,8938556,8400102,7590172,8066498,7673545,7116489,6522466,5446466,5064648,5683474,4574108,2305372,5194076,7362400,7419854,7610737,7923905,7117901,6152460,5486010,4264807,5446854,8234794,7831843,7206673,7885361,7308461,7048481,6695905,6398153,6000072,5646858,4823630,5233359,7279073,6986937,7600470,8098162,6914791,7381156,7369580,6853944,6663305,6135048,5823069,6102161,8283808,8016456,9359447,9246242,8151646,8817230]
rand1 = [0.5687,-0.9882,0.1189,-1.2601,-0.3911,1.9445,0.3316,-0.1481,0.4068,0.7671,0.8271,0.2716,-1.4072,0.4728,-0.9619,0.9173,-0.0821,-1.1588,0.0765,0.1755,-0.5259,-1.4256,1.3475,0.5346,0.471,-0.3013,0.7962,-0.7041,-0.2626,1.0618,-0.7738,-2.6074,-0.2967,1.7393,0.3519,1.176,1.2069,2.001,2.1573,0.1282,0.1068,-0.2681,1.0069,0.5927,-1.2703,-0.0711,-0.9,-0.0616,-1.3429,-0.0401,1.0748,-1.1614,-0.6819,-1.4115,0.0691,-1.0553,-0.93,1.2836,-1.7831,-0.7062,-1.0082,1.0524,1.5953,1.2455,0.8654,0.8777,-1.4663,-0.4333,-0.8127,-0.845,-0.948,-0.6094,-0.1344,0.9685,-0.1491,0.1436,1.7774,1.0366,0.8299,0.561,0.8791,0.7471,-1.6092,0.6296,-1.3406,-1.7664,-1.4931,-0.5876,-1.3118,0.4803,-0.2882,2.1569,-0.6655,-1.0178,0.8228,1.6798,2.3363,-0.6074,1.4136,2.3746,0.7793,-1.1287,0.6165,-0.4108,-0.2369,0.0369,-1.1097,-0.6431,1.3221,0.5657,-0.4914,-0.4554,-1.5849,0.4813,-1.2737,-0.0796,0.4004,-1.738,0.1925,1.1093,0.0209,0.6383,0.6414,-0.8735,-0.088,-0.9283,2.0551,-0.136,0.1777,0.8772,0.5376,-1.2647,1.071,0.2456,-1.0931,-0.0118,0.6261,-0.587,-1.2294,-0.4165,0.5345,1.0869,-0.9818,0.4787,-1.3789,1.3529,0.6653,-0.8275,-0.5914,-0.7355,0.0025,1.4563,-0.0898,-1.5065,0.4905,0.4267,1.5735,1.6162,0.0042,-0.8997,0.8872,0.2177,-0.2742,-0.0914,-0.9045,0.4791,0.9858,-0.5043,-0.8218,0.5795,1.1364,0.7795,0.2155,0.3003,1.335,1.1247,-0.6261,0.6944,0.7684,0.7753,-0.6865,0.9433,-0.8882,0.1489,0.8787,0.4825,1.6892,0.4575,0.0787,0.0675,-0.86,-0.914,-0.1587,-0.5791,-3.0869,0.3754,-1.598,-1.2995,-0.5107,0.0434]
rand2 = [-0.1704,-0.031,-0.9051,1.3667,-0.6603,-1.2154,0.4385,0.0046,-0.901,-1.2074,0.967,1.5714,-1.7821,-0.8662,-0.6328,1.68,-0.5189,0.6465,0.2242,0.0035,-1.4844,0.9738,1.9551,2.4202,-0.5543,2.4926,-1.3705,-0.5917,0.3687,0.6026,1.3289,-1.2352,0.3733,-1.5046,-1.1465,-0.6998,1.1829,0.9636,-2.5403,-0.0889,0.222,-0.2371,-0.2622,-0.318,-0.7091,2.1513,-1.8727,1.9292,-0.5143,-1.1911,0.7576,0.0317,0.4863,1.3735,0.5418,0.7537,-0.6496,-0.686,-0.9757,-0.7936,2.1179,0.0297,0.8527,0.5862,0.3971,-0.1645,-0.0801,-1.5308,0.3307,1.0911,-0.1486,1.4192,-1.2795,0.1377,0.6074,0.4261,2.8731,-0.8682,0.5553,0.6402,0.2486,0.1287,0.4496,-0.1236,1.2351,1.5403,-1.9935,0.0496,-0.2966,-0.2954,0.3419,0.6887,2.1978,-0.0516,2.4479,1.0854,-0.6392,1.3028,0.0393,2.629,-1.354,-0.1778,-0.4331,0.747,0.987,0.7355,-1.0862,0.1334,-1.6203,-0.5428,-0.395,-1.3743,0.1074,0.9704,-0.477,-0.1549,0.7942,-0.8713,-0.2082,-0.1651,-0.1024,0.6153,-1.0785,0.5474,-0.3285,0.0196,0.0858,-0.8818,-0.6434,0.5494,0.2669,-0.9273,0.5372,1.3082,-1.0465,-0.827,-0.235,0.6867,0.5845,0.4367,0.4999,-1.3073,-0.5405,0.3379,0.2777,-1.6883,0.377,0.4937,-1.7551,0.083,0.9544,-1.031,0.0161,0.5916,0.385,-1.3268,1.0003,-0.1609,0.1423,1.4889,-0.8451,0.9358,1.5615,-0.9011,1.1147,0.3253,-0.0619,0.7079,-1.1104,-0.9596,0.2851,0.4034,-1.1073,-1.4975,1.1099,0.4102,1.2365,1.1653,-0.8865,-1.7562,-0.4068,0.2453,-1.6118,-1.3843,1.6611,2.1868,-0.002,-0.2606,0.4229,0.3741,-0.7955,-0.8958,-1.8156,-0.9431,-0.4636,-1.1189,1.3201,0.2129,-1.1911,-1.5737]
rand3 = [0.4,-1.244,-0.6624,-0.2374,0.8301,0.1963,-1.0709,-2.1135,-0.9823,-0.4708,1.7067,2.0829,0.9164,-1.2108,0.95,-0.0411,1.2794,-0.4177,-1.4433,-0.6785,-0.3556,0.2837,-0.4542,1.2275,-1.4683,-0.2391,1.3763,0.0039,0.2075,-0.002,1.818,-0.217,1.3371,0.3491,-0.9266,0.1919,1.2281,0.1045,1.2826,-0.0476,-1.2573,-0.5801,-0.4852,-0.2036,0.1492,-1.223,-0.0156,-0.0776,-0.3095,-0.578,-0.8226,-0.1801,0.8687,-0.6018,0.5643,-0.5356,-0.133,0.3345,-0.8733,-0.1184,2.5991,-0.4902,-0.9866,-3.0948,-0.8492,0.0724,0.9559,0.693,-0.4897,-0.4258,0.5164,-0.121,-1.5062,0.5266,-1.5228,-0.7205,0.0551,1.0677,-0.0706,-0.3775,-0.7217,-1.6799,-0.3464,-0.7523,-1.509,0.3666,0.5706,-0.1025,-1.5335,0.054,0.5089,1.0493,-0.7767,-1.1604,-0.0672,1.5049,0.2447,-1.0308,-0.0407,-0.7553,1.1118,-0.5535,2.451,0.3446,0.8431,0.4375,-1.7314,-1.2065,-0.5337,3.4444,0.3097,-0.9857,-1.5802,-0.8664,0.6159,2.6515,1.2974,1.0753,1.4807,-0.9055,-0.6936,-0.1725,-0.1754,0.4146,-1.6657,-0.8932,0.0715,-0.1362,-1.7372,-0.2238,1.7457,-0.3934,0.35,0.523,1.5334,0.9833,0.0413,1.1863,-0.2761,-0.2063,0.0671,-0.5428,1.9861,0.5102,0.775,-0.1617,0.9135,0.0869,0.64,0.3292,-0.7374,0.3909,0.3401,-0.9863,0.5278,-0.4481,-0.6161,-0.9546,-1.4581,0.0495,1.1513,-0.5621,0.4348,0.3397,-0.0318,-1.1157,0.6585,-0.2495,-1.0561,-1.9686,0.4416,-1.5094,-2.0153,-0.5641,0.5587,0.1942,-1.8782,-1.8311,1.0107,-0.3177,-1.7795,0.5776,-0.8266,0.7934,0.3244,-0.4894,0.0459,-0.0275,1.0859,0.9312,-1.1304,-0.4712,0.8873,0.766,1.3654,0.0076,0.976,-0.166,-0.3933,0.597]
# FRED TOTBUSIMNSA
inventories = TSeries(1991M1, [802948, 809329, 813301, 819247, 815688, 812610, 817899, 820061, 823912, 844117, 850772, 823633, 830472, 837696, 845466, 851007, 848150, 840682, 841820, 843790, 851014, 872794, 881832, 850662, 857823, 867791, 869132, 876216, 883463, 879098, 886582, 894296, 903536, 932673, 944083, 913178, 930073, 943250, 951783, 964551, 966416, 959054, 963639, 966512, 974748, 1005190, 1013264, 971548, 985288, 992520, 989270, 997607, 993342, 981384, 987780, 989675, 996161, 1026552, 1032049, 990236, 1001594, 1011593, 1010703, 1020615, 1018096, 1012936, 1016327, 1017650, 1029939, 1061105, 1068905, 1031141, 1042099, 1055958, 1060445, 1067950, 1060760, 1049957, 1053376, 1056507, 1067240, 1097690, 1107522, 1062675, 1071035, 1082979, 1090302, 1098322, 1094943, 1086975, 1091848, 1094423, 1107696, 1141338, 1159390, 1121998, 1134371, 1146568, 1150610, 1162620, 1162809, 1162473, 1162945, 1171166, 1178706, 1216296, 1229002, 1180188, 1191951, 1191439, 1186330, 1189533, 1180738, 1161695, 1152536, 1150828, 1152421, 1165237, 1157597, 1103923, 1111640, 1112071, 1109602, 1111506, 1108397, 1102590, 1106888, 1107788, 1123981, 1155466, 1163421, 1124357, 1133336, 1148853, 1152247, 1155995, 1143502, 1132545, 1127423, 1119164, 1132069, 1167310, 1176290, 1133494, 1142349, 1159588, 1172616, 1182818, 1181878, 1186159, 1194192, 1201482, 1211812, 1248972, 1269840, 1225450, 1245168, 1261228, 1272998, 1281111, 1273841, 1266265, 1259652, 1262073, 1279664, 1316722, 1332567, 1296279, 1314928, 1326292, 1342439, 1354566, 1361158, 1366616, 1371049, 1378410, 1394671, 1427827, 1440290, 1389464, 1404113, 1417759, 1421965, 1432810, 1434501, 1435032, 1437124, 1439626, 1460055, 1495048, 1510232, 1467827, 1492578, 1507570, 1508679, 1518447, 1511935, 1515048, 1527089, 1525299, 1528977, 1544889, 1530433, 1447083, 1439167, 1425061, 1406341, 1390417, 1365989, 1343414, 1331264, 1312360, 1318473, 1351866, 1364032, 1314711, 1324991, 1339537, 1349848, 1357098, 1352966, 1356614, 1370907, 1380956, 1408712, 1453296, 1466048, 1432436, 1455698, 1471379, 1492992, 1507258, 1515928, 1512044, 1521993, 1529029, 1538145, 1582704, 1590660, 1545609, 1567020, 1587969, 1597527, 1606183, 1603608, 1593978, 1609371, 1615986, 1640806, 1681384, 1687692, 1635359, 1666318, 1674942, 1676321, 1682798, 1669754, 1656544, 1666687, 1673769, 1696544, 1744996, 1754594, 1703784, 1729329, 1745613, 1754664, 1765601, 1761193, 1749824, 1761654, 1764051, 1781960, 1823893, 1828731, 1768620, 1786027, 1797721, 1802099, 1812342, 1802493, 1801416, 1806687, 1805867, 1827359, 1865936, 1862707, 1803264, 1818881, 1819586, 1830558, 1836272, 1827236, 1819262, 1819216, 1820815, 1841062, 1874260, 1890039, 1837538, 1859213, 1868841, 1875952, 1872678, 1865192, 1863610, 1867788, 1879852, 1899300, 1932109, 1944985, 1896032, 1927087, 1944782, 1944271, 1947393, 1938113, 1928497, 1937876, 1948180, 1973699, 2018525, 2019876, 1980546, 2019358, 2034293, 2032390, 2043268, 2034278, 2022725, 2028440, 2025575, 2040535, 2077337, 2074770, 2020662, 2038753, 2034414, 2026781, 1999651, 1935469, 1903697, 1907634, 1912619, 1944565, 1996118, 2008212, 1974406, 2009883, 2033227, 2039642, 2042900, 2041201, 2049889, 2071015, 2086983, 2132147, 2198902, 2235535, 2238164, 2295117, 2343973, 2404147, 2428332, 2447947, 2472266, 2477207, 2494999, 2522763, 2567129, 2573215, 2516894, 2538524, 2546010, 2554013, 2552240, 2534742, 2522767, 2511881, 2522326, 2554003])

@testset "X13 Arima run" begin
    ts = TSeries(1950Q1, mvsales[1:150])
    xts = X13.series(ts, title="Quarterly Grape Harvest")
    spec = X13.newspec(xts)
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.estimate!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    @test res isa X13.X13result
    for key in (:a1, :a3, :b1, :ref, :rrs, :rsd)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :ac2, :acf, :pcf)
        @test res.tables[key] isa X13.WorkspaceTable
    end
    
    # Manual example 2 
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    X13.arima!(spec, X13.ArimaModel(2,1,0,0,1,1))
    X13.estimate!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    
    for key in (:a1, :a3, :b1, :ref, :rrs, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acf, :acm, :itr, :pcf, :rts, :sp0, :spr)
        @test res.tables[key] isa X13.WorkspaceTable
    end
    for key in ( :est, :lks, :mdl,  :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 3
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    X13.regression!(spec; variables=[:seasonal, :const], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a3, :b1, :ref, :rmx, :rrs, :rsd, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acf, :itr, :pcf, :rcm, :rts, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl,  :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 4
    ts = TSeries(1950Y, mvsales[1:50])
    xts = X13.series(ts, title="Annual Olive Harvest")
    spec = X13.newspec(xts)
    X13.arima!(spec, X13.ArimaModel([2],1,0))
    X13.estimate!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :ref, :rrs, :rsd, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :acf, :ac2, :rts, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl,  :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 5
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    X13.regression!(spec, variables = :const, save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,12))
    X13.estimate!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :ref, :rmx, :rrs, :rsd, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :acf, :pcf, :sp0, :spr, :rts)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl,  :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # # Manual example 6
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales", print=[:span, :seriesplot])
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all,  print=[:aictransform, :seriesconstant])
    X13.regression!(spec, variables = [:const, :seasonal], save=:all)
    m = X13.ArimaModel(X13.ArimaSpec(1,1,0),X13.ArimaSpec(1,0,0,3),X13.ArimaSpec(0,0,1))
    X13.arima!(spec, m)
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a3, :b1, :ref, :rmx, :rrs, :rsd, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :acf, :itr, :pcf,  :rcm, :rts, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl,  :udg)
        @test res.other[key] isa AbstractWorkspace
    end
   
    
    # Manual example 7
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    X13.arima!(spec, X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12); ma = [missing, 1.0], fixma = [false, true])
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a3, :b1, :ref, :rrs, :rsd, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acf, :itr, :pcf, :rts, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
end

@testset "X13 Automdl run" begin
    # Manual example 1
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:seasonal, :const], save=:all)
    X13.automdl!(spec)
    X13.estimate!(spec, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :a3, :fct)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rts, :sp0, :sp1, :sp2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl,  :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    
    # Manual example 2
    ts = TSeries(1976M1, mvsales[200:600])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=:td, save=:all)
    X13.automdl!(spec; diff=[1,1], maxorder=[3,missing])
    X13.transform!(spec; func=:log, save=:all)
    X13.outlier!(spec; save=:all)
    X13.estimate!(spec, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :ira, :otl, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :td, :trn, :fct, :ftr)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :acm, :d8b, :pcf, :rcm, :rts, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (  :est, :lks, :mdl,  :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 3 
    ts = TSeries(1976M1, mvsales[200:400])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; aictest=:td, save=:all)
    X13.automdl!(spec) #savelog argument here...
    X13.estimate!(spec, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :a3, :fct)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :acm, :d8b, :pcf, :rts,  :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in ( :est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
end

@testset "X13 Check run" begin
    # Manual example 1
    ts = TSeries(1964M1, mvsales[150:300])
    xts = X13.series(ts, title="Monthly Retail Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:td, X13.ao(1967M6), X13.ls(1971M6), X13.easter(14)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.check!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :ao, :b1, :hol, :ls, :otl, :rmx, :td, :a3, :chl, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    
    # Manual example 2
    ts = TSeries(1964M1, mvsales[150:650])
    xts = X13.series(ts, title="Warehouse clubs and supercenters")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.ao(2000M3), X13.tc(2001M2)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.forecast!(spec, maxlead=24, save=:all)
    X13.estimate!(spec, save=:all)
    X13.check!(spec, acflimit=2.0, qlimit=0.05, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :fct, :ftr, :fvr, :otl, :ref, :rmx, :rrs, :rsd, :tc, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :acm, :itr, :pcf, :rcm, :rts, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 3
    ts = TSeries(1964M1, mvsales)
    xts = X13.series(ts, title="Warehouse clubs and supercenters")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, :seasonal, X13.ao(2000M3), X13.tc(2001M2)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.forecast!(spec, maxlead=24, save=:all)
    X13.estimate!(spec, save=:all)
    X13.check!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :fct, :ftr, :fvr, :otl, :ref, :rmx, :rrs, :rsd, :tc, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :itr, :pcf, :rcm, :rts, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
end

@testset "X13 Estimate run" begin
    # Manual example 1
    ts = TSeries(1976M1, rand1[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=:seasonal, save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1); ma=[0.25], fixma=[true])
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :ref, :rmx, :rrs, :rsd, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :rcm, :rts, :acf, :pcf, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 2
    ts = TSeries(1978M12, abs.([rand2..., rand1..., rand3...]))
    xts = X13.series(ts, title="Monthly Inventory")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.ao(1999M1)], save=:all)
    X13.arima!(spec, X13.ArimaModel(1, 1, 0, 0, 1, 1))
    X13.estimate!(spec, tol=1e-4, maxiter=100, exact=:ma, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :otl, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # test with file argument
    xts = X13.series(inventories, title="Monthly Inventory")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.estimate!(spec, file=abspath(pathof(TimeSeriesEcon),"..","..", "data","reg1.mdl"), save=:all, fix=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :ref, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :rts, :acf, :pcf, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
end

@testset "X13 Force run" begin
    # Manual example 1
    ts = TSeries(1967M1, mvsales[250:400])
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x9, save=:all)
    X13.force!(spec, start=M10, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e6a, :e7, :e8, :f1, :p6a, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :saa, :tad, :ffc)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 2
    ts = TSeries(1967M1, mvsales[250:400])
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x9, save=:all)
    X13.force!(spec, start=M10, type=:regress, rho=0.8, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e6a, :e7, :e8, :f1, :p6a, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :saa, :tad, :ffc)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 3
    ts = TSeries(1967M1, mvsales[250:400])
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x5, save=:all)
    X13.force!(spec, type=:none, round=true, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e6r, :e7, :e8, :f1, :p6r, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rnd, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end
end

@testset "X13 Forecast run" begin
    # Manual example 1
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.forecast!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :rmx, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0,)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 2
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.estimate!(spec, save=:all)
    X13.outlier!(spec; save=:all)
    X13.forecast!(spec, maxlead=24, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :fct, :ftr, :fts, :fvr, :otl, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :oit, :rcm, :rts, :acf, :pcf, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    

    # Manual example 3
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.estimate!(spec, save=:all)
    X13.forecast!(spec, maxlead=15, probability=0.90, exclude=10, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :fct, :ftr, :fvr, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :acf, :pcf, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 4
    ts = TSeries(1976M1, mvsales[1:250])
    xts = X13.series(ts, title="Monthly Sales", span=first(rangeof(ts)):1990M3)
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.estimate!(spec, save=:all)
    X13.forecast!(spec, maxlead=24, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :fct, :ftr, :fvr, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 5
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.forecast!(spec, maxback=12, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :bct, :btr, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fvr, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :tad, :td, :trn, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :acf, :pcf, :sp0, :sp1, :sp2, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 6
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.estimate!(spec, save=:all)
    X13.outlier!(spec; save=:all)
    X13.forecast!(spec, maxlead=24, lognormal=true, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :fct, :ftr, :fts, :fvr, :otl, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :oit, :rcm, :rts, :acf, :pcf, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
end

@testset "X13 History run" begin

    # Manual example 2
    ts = TSeries(1967M1, mvsales[1:50])
    xts = X13.series(ts, title="Sales of livestock")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x9, save=:all)
    X13.history!(spec, sadjlags=2, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end
    

    # Manual example 2
    ts = TSeries(1969M7, mvsales[500:650])
    xts = X13.series(ts, title="Exports of leather goods")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:const, :td, X13.ls(1972M5), X13.ls(1976M10)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 2, 1, 1, 0))
    X13.estimate!(spec, save=:all)
    X13.forecast!(spec, save=:all)
    X13.history!(spec, estimates=:fcst, fstep=1, start=1975M1, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :b1, :fce, :fch, :fct, :ftr, :fvr, :ls, :otl, :ref, :rmx, :rrs, :rsd, :td, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rot, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 3
    ts = TSeries(1969M7, mvsales[500:650])
    xts = X13.series(ts, title="Exports of leather goods")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:const, :td, X13.ls(1972M5), X13.ls(1976M10)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 2, 1, 1, 0))
    X13.estimate!(spec, save=:all)
    X13.forecast!(spec, save=:all)
    X13.history!(spec, estimates=[:arma, :fcst], start=1975M1, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :amh, :b1, :fce, :fch, :fct, :ftr, :fvr, :ls, :otl, :ref, :rmx, :rrs, :rsd, :td, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rot, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # Manual example 4
    ts = TSeries(1967M1, mvsales[100:300])
    xts = X13.series(ts, title="Housing Starts in the Midwest", comptype=:add, modelspan=X13.Span(missing,M12))
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 2, 0, 1, 1))
    X13.x11!(spec, seasonalma=:s3x3, save=:all)
    X13.history!(spec, estimates=[:sadj, :trend], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :sae, :sar, :tad, :td, :tre, :trn, :trr, :fct, :ftr, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rot, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # As example 4, but quarterly
    ts = TSeries(1967Q1, mvsales[100:300])
    xts = X13.series(ts, title="Housing Starts in the Midwest", comptype=:add, modelspan=X13.Span(missing,Q3))
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 2, 0, 1, 1))
    X13.x11!(spec, seasonalma=:s3x3, save=:all)
    X13.history!(spec, estimates=[:sadj, :trend], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :sae, :sar, :tad, :td, :tre, :trn, :trr, :fct, :ftr, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rot, :ac2, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
end

@testset "X13 Identify run" begin

    # Manual example 1
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.identify!(spec, diff=[0, 1], sdiff=[0, 1], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a3, :b1, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0,)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:iac, :ipc, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    

    # Manual example 2
    ts = TSeries(1976M1, mvsales[100:200])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:const, :seasonal], save=:all)
    X13.identify!(spec, diff=[0, 1], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :rmx, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0, :st0)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:iac, :ipc, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
      
    # Manual example 3
    ts = TSeries(1976M1, mvsales[400:500])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.easter(14)], save=:all)
    X13.identify!(spec, diff=[1], sdiff=[1], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :rmx, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0, :st0)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:iac, :ipc, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    

    # Manual example 4
    ts = TSeries(1963Q1, mvsales[300:400])
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[X13.ls(1971Q1)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.identify!(spec, diff=[0, 1], sdiff=[0, 1], maxlag=16, save=:all)
    X13.estimate!(spec, save=:all)
    X13.check!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :b1, :ls, :otl, :ref, :rmx, :rrs, :rsd, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :acm, :itr, :pcf, :rts)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :iac, :ipc, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
end

@testset "X13 Outlier run" begin

    # Manual example 1
    ts = TSeries(1976M1, mvsales[250:400])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.arima!(spec, X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.outlier!(spec, lsrun=5, types=[:ao, :ls], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :b1, :fts, :a3, :ls, :otl, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:oit, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1976M1, mvsales[400:650])
    xts = X13.series(ts, title="Monthly Sales", span=1980M1:1992M12)
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[X13.ls(1981M6), X13.ls(1990M11)], save=:all)
    X13.arima!(spec,  X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.estimate!(spec, save=:all)
    X13.outlier!(spec, types=:ao, method=:addall, critical=4.0, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :b1, :fts, :ls, :otl, :ref, :rmx, :rrs, :rsd, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :oit, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    mvsales_altered = copy(mvsales[1:250]) .* 1.0
    mvsales_altered[140:150] = mvsales_altered[140:150] .* (1/100)
    mvsales_altered[151:end] = mvsales_altered[151:end] .* 3
    # mvsales_altered[200] = mvsales_altered[200]*3
    ts = TSeries(1976M1, mvsales_altered)
    xts = X13.series(ts, title="Monthly Sales", span=1980M1:1992M12)
    spec = X13.newspec(xts)
    X13.arima!(spec,  X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.estimate!(spec, save=:all)
    X13.outlier!(spec, types=:ls, critical=3.0, lsrun=2, span=1987M1:1988M12, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :b1, :fts, :ref, :rrs, :rsd, :a3, :ls, :otl)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :oit, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 4
    mvsales_altered = copy(mvsales[1:250]) .* 1.0
    mvsales_altered[140:150] = mvsales_altered[140:150] .* (1/100)
    mvsales_altered[151:end] = mvsales_altered[151:end] .* 3
    ts = TSeries(1976M1, mvsales_altered)
    xts = X13.series(ts, title="Monthly Sales", span=1980M1:1992M12)
    spec = X13.newspec(xts)
    X13.arima!(spec,  X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.estimate!(spec, save=:all)
    X13.outlier!(spec, critical=[3.0, 4.5, 4.0], types=:all, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :b1, :fts, :ref, :rrs, :rsd, :a3, :ao, :ls, :otl, :tc)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :oit, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end


end

@testset "X13 Pickmdl run" begin

    models1 = [
        X13.ArimaModel(0,1,1,0,0,1; default=true)
        X13.ArimaModel(0,1,2,0,0,1;)
        X13.ArimaModel(2,1,0,0,0,1;)
        X13.ArimaModel(0,2,2,0,0,1;)
        X13.ArimaModel(2,1,2,0,0,1;)
    ]
    models2 = [
        X13.ArimaModel(0,1,1,0,1,1; default=true)
        X13.ArimaModel(0,1,2,0,1,1;)
        X13.ArimaModel(2,1,0,0,1,1;)
        X13.ArimaModel(0,2,2,0,1,1;)
        X13.ArimaModel(2,1,2,0,1,1;)
    ]

    # Manual example 1
    ts = TSeries(1976M1, mvsales[50:250])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, :seasonal], save=:all)
    X13.pickmdl!(spec, models1, mode=:fcst)
    X13.estimate!(spec, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :td, :trn, :fct, :ftr)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :d8b, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1976M1,  mvsales[100:200])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.pickmdl!(spec, models2, mode=:fcst, method=:first, fcstlim=20, qlim=10, overdiff=0.99, identify=:all)
    X13.estimate!(spec, save=:all)
    X13.outlier!(spec; save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :td, :trn, :fct, :ftr)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :d8b, :rcm, :rts, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    ts = TSeries(1976M1, mvsales[50:250])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=:td, save=:all)
    X13.pickmdl!(spec, models1, mode=:fcst, outofsample=true)
    X13.estimate!(spec, save=:all)
    X13.outlier!(spec; save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :d8b, :rcm, :rts, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 1, but with file argument
    ts = TSeries(1976M1, mvsales[50:250])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, :seasonal], save=:all)
    X13.pickmdl!(spec, file=abspath(pathof(TimeSeriesEcon),"..","..", "data","pickmdl.mdl"), mode=:fcst)
    X13.estimate!(spec, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :td, :trn, :fct, :ftr)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :d8b, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

end

@testset "X13 Regression run" begin

    # Manual example 1
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:const, :seasonal], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :ref, :rmx, :rrs, :rsd, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :rcm, :rts, :acf, :pcf, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1976M1, mvsales[100:150])
    xts = X13.series(ts, title="Irregular Component of Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:const, X13.sincos([4,5])], save=:all)
    X13.estimate!(spec, save=:all)
    X13.spectrum!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :ref, :rmx, :rrs, :rsd, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :rcm, :sp0, :spr, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    ts = TSeries(1976M1, mvsales[150:300])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.easter(8), X13.labor(10), X13.thank(3)], save=:all)
    X13.identify!(spec, diff=[0, 1], sdiff=[0, 1], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :rmx, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0, :st0)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:iac, :ipc, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 4
    ts = TSeries(1976M1, mvsales[50:100])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:tdnolpyear, :lom, X13.easter(8), X13.labor(10), X13.thank(3)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a3, :b1, :hol, :ref, :rmx, :rrs, :rsd, :td, :trn, :chl)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :acf, :pcf, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 5
    ts = TSeries(1990M1, mvsales[500:600])
    xts = X13.series(ts, title="Retail inventory of food products")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.tdstock1coef(31), X13.easterstock(8)], aictest = [:td, :easter], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :tad, :td, :trn, :fct, :ftr, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end


    # Manual example 6
    ts = TSeries(1990Q1, mvsales[300:450])
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.ao(2007Q1), X13.rp(2005Q2,2005Q4), X13.ao(1998Q1), :td], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :ls, :otl, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :ac2, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
 
    # Manual example 7
    ts = TSeries(1990Q1, mvsales[1:150])
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.ao(2007Q1), X13.qi(2005Q2,2005Q4), X13.ao(1998Q1), :td], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :ls, :otl, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :ac2, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 8
    # TODO: parse data output from regression spec / model file
    ts = TSeries(1990Q1, mvsales[101:250])
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.ao(2007Q1), X13.qi(2005Q2,2005Q4), X13.ao(1998Q1), :td], user=:tls, data=MVTSeries(1990Q1, [:tls], mvsales[51:200]), save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :ls, :otl, :ref, :rmx, :rrs, :rsd, :td, :trn, :usr)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :ac2, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 9
    ts = TSeries(1981Q1, mvsales[75:150])
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=X13.tl(1985Q3,1987Q1), save=:all)
    X13.identify!(spec, diff=[0,1], sdiff=[0,1], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :rmx, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:iac, :ipc, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 10
    ts = TSeries(1970M1, mvsales[501:550])
    xts = X13.series(ts, title="Monthly Riverflow")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:seasonal, :const], data=MVTSeries(1960M1, [:temp, :precip], hcat(rand1[1:171],rand2[1:171])), save=:all)
    X13.arima!(spec, X13.ArimaModel(3, 0, 0, 0, 0, 0))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :ref, :rmx, :rrs, :rsd, :usr, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :acf, :pcf, :sp0, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 11
    ts = TSeries(1967M1, mvsales[201:450])
    xts = X13.series(ts, title="Retail Inventory - Family Apparel", type=:stock)
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.tdstock(31), X13.ao(1980M7)], aictest=:tdstock, save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 0, 0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a3, :ao, :b1, :otl, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:rcm, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 12
    ts = TSeries(1976M1, mvsales[151:300])
    xts = X13.series(ts, title="Retail Sales - Televisions", type=:flow)
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.td(1985M12), X13.seasonal(1985M12)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 13
    ts = TSeries(1976M1, mvsales[401:550])
    xts = X13.series(ts, title="Retail Sales - Televisions", type=:flow)
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.td(1985M12, :zerobefore), :seasonal, X13.seasonal(1985M12, :zerobefore)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :ref, :rmx, :rrs, :rsd, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 14
    ts = TSeries(1993Q1, mvsales[201:350])
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.ao(2001Q3), X13.ls(2007Q1), X13.ls(2007Q3), X13.ao(2008Q4)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :a3, :ao, :b1, :ls, :otl, :ref, :rmx, :rrs, :rsd, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :ac2, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 15
    ts = TSeries(1993Q1, mvsales[101:250])
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.ao(2001Q3), X13.tl(2007Q1,2007Q2), X13.ao(2008Q4)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :a3, :ao, :b1, :ls, :otl, :ref, :rmx, :rrs, :rsd, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :ac2, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 16
    ts = TSeries(1993Q1, mvsales[1:150])
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.ao(2001Q3), X13.lss(2007Q1,2007Q3), X13.ao(2008Q4)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :a3, :ao, :b1, :ls, :otl, :ref, :rmx, :rrs, :rsd, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :itr, :rcm, :rts, :ac2, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 17
    ts = TSeries(1980M1, mvsales[101:150])
    xts = X13.series(ts, title="Exports of pasta products")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:const, :td], save=:all)
    X13.automdl!(spec)
    X13.x11!(spec, mode=:add, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :tad, :td, :a3, :fct, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :acf, :pcf, :sp0, :sp1, :sp2, :spr)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 18
    ts = TSeries(1975M1, mvsales[1:250])
    xts = X13.series(ts, title="Retail sales of children's apparel")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:const, :td, X13.ao(1976M1), X13.ls(1991M12), X13.easter(8), :seasonal],
        data=MVTSeries(1975M1, [:sale88, :sale89, :sale90], hcat([rand1..., rand2[1:74]...], [rand2..., rand3[1:74]...],[rand3..., rand1[1:74]...])), save=:all
    )
    X13.arima!(spec, X13.ArimaModel(2,1,0))
    X13.forecast!(spec, maxlead=24, save=:all)
    X13.x11!(spec, appendfcst=true, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 19
    ts = TSeries(1975M1, mvsales[1:250])
    sale88 = zeros(250+24)
    sale89 = zeros(250+24)
    sale90 = zeros(250+24)
    sale88[100] = 1.0
    sale89[110] = 1.0
    sale90[50] = 1.0
    xts = X13.series(ts, title="Retail sales of children's apparel")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:const, :td, X13.ao(1976M1), X13.ls(1991M12), X13.easter(8), :seasonal],
        data=MVTSeries(1975M1, [:sale88, :sale89, :sale90], hcat(sale88,sale89,sale90)),
        usertype=:ao, save=:all
    )
    X13.arima!(spec, X13.ArimaModel(2,1,0))
    X13.forecast!(spec, maxlead=24, save=:all)
    X13.x11!(spec, appendfcst=true, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chl, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fvr, :hol, :ira, :ls, :otl, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :tad, :tal, :td, :trn, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 20
    ts = TSeries(1975M1, mvsales[101:250])
    xts = X13.series(ts, title="Midwest total starts")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[X13.ao(1977M1), X13.ls(1979M1), X13.ls(1979M3), X13.ls(1980M1), :td],
        b = [-0.7946, -0.8739, 0.6773, -0.6850, 0.0209, 0.0107, -0.0022, 0.0018, 0.0088, -0.0075],
        fixb = [true, true, true, true, false, false, false, false, false, false], save=:all
    )
    X13.arima!(spec, X13.ArimaModel(0,1,2,0,1,1))
    X13.estimate!(spec, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :ira, :ls, :otl, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :tal, :td, :trn, :fct, :ftr)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :d8b, :itr, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 21
    ts = TSeries(1975M1, mvsales[500:650])
    xts = X13.series(ts, title="Department store sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.easter(8)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec; save=:all)
    X13.estimate!(spec, save=:all)
    X13.check!(spec, save=:all)
    X13.forecast!(spec, save=:all)
    X13.x11!(spec, mode=:mult, seasonalma=:s3x3, title=["Department Store Retail Sales Adjusted For", "Outlier, Trading Day, and Holiday Effects"], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :a2, :a3, :ao, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chl, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fts, :fvr, :hol, :ira, :otl, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :acm, :d8b, :itr, :oit, :pcf, :rcm, :rts, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 22
    ts = TSeries(1975M1, mvsales[151:300])
    xts = X13.series(ts, title="Department store sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.easter(8), X13.easter(0)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec; save=:all)
    X13.estimate!(spec, save=:all)
    X13.check!(spec, save=:all)
    X13.forecast!(spec, save=:all)
    X13.x11!(spec, mode=:mult, seasonalma=:s3x3, title=["Department Store Retail Sales Adjusted For", "Outlier, Trading Day, and Holiday Effects"], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chl, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fts, :fvr, :hol, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :td, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :acm, :d8b, :itr, :oit, :pcf, :rcm, :rts, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 23
    ts = TSeries(1975M1, mvsales[400:500])
    xts = X13.series(ts, title="Department store sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.easter(8), X13.easter(0)], aictest=[:td, :easter], testalleaster=true, save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec; save=:all)
    X13.estimate!(spec, save=:all)
    X13.check!(spec, save=:all)
    X13.forecast!(spec, save=:all)
    X13.x11!(spec, mode=:mult, seasonalma=:s3x3, title=["Department Store Retail Sales Adjusted For", "Outlier, Trading Day, and Holiday Effects"], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fts, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acf, :acm, :d8b, :oit, :pcf, :rts, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 24
    ts = TSeries(1990Q1, mvsales[1:50])
    xts = X13.series(ts, title="US Total Housing Starts")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec;
        data=MVTSeries(1985Q1, [:s1, :s2, :s3], hcat(rand1[1:94],rand2[1:94], rand3[1:94] )),
        usertype=:seasonal, save=:all
    ),
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.outlier!(spec; save=:all)
    X13.forecast!(spec, maxlead=24, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a10, :a3, :b1, :fct, :ftr, :fts, :fvr, :rmx, :trn, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:oit, :ac2, :acf, :pcf)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 25
    ts = TSeries(1991M1, mvsales[101:250])
    xts = X13.series(ts, title="Payment to family nanny, taiwan", span=X13.Span(1993M1))
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec;
        variables=[X13.ao(1995M9), X13.ao(1997M1), X13.ao(1997M2)],
        data=MVTSeries(1991M1, [:beforecny, :betweencny, :aftercny, :beforemoon, :betweenmoon, :aftermoon, :beforemidfall, :betweenmidfall, :aftermidfall], round.(hcat(rand1[1:162] .^ 2,rand2[1:162]  .^ 2,rand3[1:162]  .^2,rand1[1:162]  .^ 3,rand2[1:162]  .^ 3,rand3[1:162]  .^ 3,rand1[1:162]  .^ 4,rand2[1:162]  .^ 4,rand3[1:162] .^ 4), digits=4)),
        usertype=[:holiday, :holiday, :holiday, :holiday2, :holiday2, :holiday2, :holiday3, :holiday3, :holiday3],
        chi2test = true, save=:all
    )
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,0))
    X13.check!(spec, save=:all)
    X13.forecast!(spec, maxlead=12, save=:all)
    X13.estimate!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :a3, :ao, :b1, :fct, :ftr, :fvr, :otl, :ref, :rmx, :rrs, :rsd, :trn)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acf, :itr, :pcf, :rcm, :rts, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end
    
end

@testset "X13 Seats run" begin
    # Manual example 1
    ts = TSeries(1987M1, mvsales[101:550])
    # ts = TSeries(1987M1, collect(1:150))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:auto, save=:all)
    X13.regression!(spec; aictest=:td, save=:all)
    X13.automdl!(spec)
    X13.outlier!(spec, types=[:ao, :ls, :tc], save=:all)
    X13.forecast!(spec, maxlead=36, save=:all)
    X13.seats!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:tbs, :a3, :afd, :ao, :cyc, :dor, :dsa, :dtr, :fct, :ftr, :fvr, :ltt, :otl, :psc, :psi, :pss, :rmx, :s10, :s11, :s12, :s13, :s14, :s16, :s18, :sfd, :ssm, :td, :tfd, :trn, :yfd, :a1, :a18, :a19, :ase, :b1, :cse, :rrs, :se2, :se3, :sse, :tse)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:wkf, :ac2, :acf, :pcf, :s1s, :s2s, :sp0, :spr, :st0, :str, :t1s, :t2s, :rog)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:mdc, :est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1990Q1, mvsales[100:150])
    xts = X13.series(ts)
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; aictest=:td, save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.forecast!(spec, maxlead=12, save=:all)
    X13.seats!(spec, finite=true, save=:all)
    X13.history!(spec, estimates=[:sadj, :trend], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:tbs, :a3, :afd, :cyc, :dor, :dsa, :dtr, :fct, :ftr, :ltt, :psi, :pss, :rmx, :s10, :s11, :s12, :s13, :s16, :s18, :sae, :sar, :sfd, :ssm, :tfd, :tre, :trn, :trr, :a1, :ase, :b1, :se2, :se3, :sse, :tse)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:fac, :faf, :ftc, :ftf, :gac, :gaf, :gtc, :gtf, :rot, :tac, :ttc, :wkf, :ac2, :acf, :pcf, :rog)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:mdc, :est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    ts = TSeries(MIT{YPFrequency{6}}(1995*6), mvsales[50:150])
    xts = X13.series(ts, title="Model based adjustment of Bimonthly exports")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec, types=[:ao, :ls, :tc], save=:all)
    X13.forecast!(spec, maxlead=18, save=:all)
    X13.seats!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:tbs, :a3, :afd, :cyc, :dor, :dsa, :dtr, :fct, :ftr, :fts, :ltt, :psi, :pss, :s10, :s11, :s12, :s13, :s16, :s18, :sfd, :ssm, :tfd, :trn, :a1, :ase, :b1, :se2, :se3, :sse, :tse)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:oit, :wkf, :ac2, :acf, :pcf, :rog)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:mdc, :est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Example with tabtables
    ts = TSeries(1990Q1, mvsales[100:150])
    xts = X13.series(ts)
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; aictest=:td, save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.forecast!(spec, maxlead=12, save=:all)
    X13.seats!(spec, tabtables=[:xo,:n,:s,:p], printphtrf=false, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:tbs, :a3, :afd, :cyc, :dor, :dsa, :dtr, :fct, :ftr, :ltt, :psi, :pss, :rmx, :s10, :s11, :s12, :s13, :s16, :s18, :sfd, :ssm, :tfd, :trn, :a1, :ase, :b1, :se2, :se3, :sse, :tse)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:wkf, :ac2, :acf, :pcf, :rog)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:mdc, :est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

end

@testset "X13 Slidingspans run" begin

    # Manual example 1
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Tourist")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=:s3x9, save=:all)
    X13.slidingspans!(spec, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1967Q1, mvsales[1:150])
    xts = X13.series(ts, title="Quarterly stock prices on NASDAQ")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=[:s3x9, :s3x9, :s3x5, :s3x5], trendma=7, mode=:logadd, save=:all)
    X13.slidingspans!(spec, cutseas = 5.0, cutchng = 5.0, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chs, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :sfs, :tad, :ycs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b,)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    ts = TSeries(1980M1, mvsales[301:500])
    xts = X13.series(ts, title="Number of employed machinists - X-11")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables = [:const, :td, X13.rp(1982M5,1982M10)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,2,0,1,1))
    X13.outlier!(spec; save=:all)
    X13.estimate!(spec, save=:all)
    X13.check!(spec, save=:all)
    X13.forecast!(spec, save=:all)
    X13.x11!(spec, mode=:add, save=:all)
    X13.slidingspans!(spec, outlier=:keep, length=144, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chs, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fts, :fvr, :ls, :otl, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :sfs, :tad, :tal, :td, :ycs, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :acm, :d8b, :itr, :oit, :pcf, :rcm, :rts, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 4
    ts = TSeries(1980M1, mvsales[151:450])
    xts = X13.series(ts, title="Number of employed machinists - Seats")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables = [:const, :td, X13.rp(1982M5,1982M10)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,2,0,1,1))
    X13.outlier!(spec; save=:all)
    X13.estimate!(spec, save=:all)
    X13.check!(spec, save=:all)
    X13.forecast!(spec, save=:all)
    X13.seats!(spec, save=:all)
    X13.slidingspans!(spec, outlier=:keep, length=144, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:tbs, :a1, :a18, :a19, :ao, :b1, :chs, :fct, :ftr, :fts, :fvr, :ls, :otl, :ref, :rmx, :rrs, :rsd, :sfs, :td, :ycs, :a3, :afd, :ase, :cse, :dor, :dsa, :dtr, :s10, :s11, :s12, :s13, :s14, :s16, :s18, :se2, :se3, :sfd, :sse, :ssm, :tfd, :tse, :yfd)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:ac2, :acf, :acm, :itr, :oit, :pcf, :rcm, :rts, :s1s, :s2s, :sp0, :spr, :st0, :str, :t1s, :t2s)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 5
    ts = TSeries(1975M1, mvsales[51:300])
    xts = X13.series(ts, title="Cheese sales in Wisconsin")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    X13.regression!(spec; variables = [:const, :seasonal, :tdnolpyear], save=:all)
    X13.arima!(spec, X13.ArimaModel(3,1,0))
    X13.forecast!(spec, maxlead=60, save=:all)
    X13.x11!(spec, appendfcst=true, save=:all)
    X13.slidingspans!(spec, fixmdl=false, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a3, :ads, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chs, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fvr, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :sfs, :tad, :td, :tds, :trn, :ycs, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 6
    ts = TSeries(1967Q1, mvsales[401:550])
    xts = X13.series(ts, title="Quarterly stock prices on NASDAQ")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=:s3x9, save=:all)
    X13.slidingspans!(spec, length=40, numspans=3, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chs, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :sfs, :tad, :ycs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b,)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end
end

@testset "X13 Spectrum run" begin

    # Manual example 1
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Klaatu")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=:s3x9, trendma=23, save=:all)
    X13.spectrum!(spec, logqs=true, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1967M1, mvsales[51:450])
    xts = X13.series(ts, title="Spectrum analysis of Building Permits Series")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.spectrum!(spec, start=1987M1, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0, :st0)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    ts = TSeries(1967M1, mvsales[101:250])
    xts = X13.series(ts, title="TOTAL ONE-FAMILY Housing Starts")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=[:s3x9], title="Composite adj. of 1-Family housing starts", save=:all)
    X13.spectrum!(spec, type=:periodogram, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 4
    ts = TSeries(1988M1, mvsales[201:350])
    xts = X13.series(ts, title="Total U.S. Retail Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, save=:all)
    X13.regression!(spec; variables=[:td, X13.easter(8), X13.labor(8)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.forecast!(spec, maxlead=60, save=:all)
    X13.spectrum!(spec, logqs=true, qcheck=true, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chl, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fvr, :hol, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :tad, :td, :trn, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :spr, :str, :ac2, :acf, :pcf, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg,)
        @test res.other[key] isa AbstractWorkspace
    end

end

@testset "X13 Transform run" begin

    # Manual example 1
    ts = TSeries(1967M1, mvsales[51:200])
    xts = X13.series(ts, title="Transform example")
    spec = X13.newspec(xts)
    X13.transform!(spec; data=TSeries(1967M1,rand1[1:150] .^ 2), mode=:ratio, adjust=:lom, func=:log, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a2p, :b1)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0, :st0)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1997Q1, mvsales[101:300])
    xts = X13.series(ts, title="Transform example")
    spec = X13.newspec(xts)
    X13.transform!(spec; constant=45.0, func=:auto, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a1c, :b1)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    ts = TSeries(1980M1, mvsales[301:400])
    xts = X13.series(ts, title="Total U.S. Retail Sales --- Current Dollars")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, data=TSeries(1970M1,collect(0.1:0.1:23.0)), title="Consumer Price Index", save=:all )
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a2, :a2p, :b1)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0, :st0)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 4
    ts = TSeries(1980M1, mvsales[301:400])
    xts = X13.series(ts, title="Total U.S. Retail Sales --- Current Dollars")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, data=TSeries(1970M1,collect(0.1:0.1:23.0)), title="Consumer Price Index", type=:temporary, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a2, :a2t, :b1)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0, :st0)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 5
    ts = TSeries(1901Q1, mvsales[1:50])
    xts = X13.series(ts, title="Annual Rainfall")
    spec = X13.newspec(xts)
    X13.transform!(spec; power=.3333, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end


    # Manual example 7
    ts = TSeries(1978M1, mvsales[401:550])
    xts = X13.series(ts, title="Total U.K. Retail Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:auto, aicdiff=0.0, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:sp0, :st0)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

end

@testset "X13 x11 run" begin

    # Manual example 1
    ts = TSeries(1976M1, mvsales[1:250])
    xts = X13.series(ts, title="Klaatu")
    spec = X13.newspec(xts)
    X13.x11!(spec; save=:all)
    X13.spectrum!(spec, logqs=true, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1976M1, mvsales[201:450]) 
    xts = X13.series(ts, title="Klaatu")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x9, trendma=23, save=:all)
    X13.x11regression!(spec, variables=:td, aictest=:td, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b14, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c14, :c16, :c17, :c19, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :xrm)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rcm, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    ts = TSeries(1967Q1, mvsales[250:500])
    xts = X13.series(ts, title="Quarterly housing starts")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=[:s3x3, :s3x3, :s3x5, :s3x5], trendma=7, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b,)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 4
    ts = TSeries(1969M7, mvsales[301:550])
    xts = X13.series(ts, title="Exports of leather goods")
    spec = X13.newspec(xts)
    X13.regression!(spec, variables=[:const, :td, X13.ls(1972M5), X13.ls(1976M10)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,2,1,1,0))
    X13.estimate!(spec, save=:all)
    X13.forecast!(spec, maxlead=0, save=:all)
    X13.x11!(spec, mode=:add, sigmalim=[2.0, 3.5], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a19, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :ls, :otl, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :ref, :rmx, :rrs, :rsd, :tad, :tal, :td, :a3)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:acm, :d8b, :itr, :rcm, :rts, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :lks, :mdl, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 5
    ts = TSeries(1985M1, mvsales[201:450])
    xts = X13.series(ts, title="Unit Auto Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    sale88 = TSeries(1984M1, zeros(length(ts) + 24))
    sale88[1988M3:1988M11] .= 1.0
    sale90 = TSeries(1984M1, zeros(length(ts) + 24))
    sale90[1990M2:1990M7] .= 1.0
    X13.regression!(spec, variables=[:const, :td], 
        data=MVTSeries(; sale88 = sale88, sale90 = sale90), save=:all
    )
    X13.arima!(spec, X13.ArimaSpec(3,1,0), X13.ArimaSpec(0,1,1,12))
    X13.forecast!(spec, maxlead=12, maxback=12, save=:all)
    X13.x11!(spec, title=["Unit Auto Sales", "Adjusted for special sales in 1988, 1990"], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a18, :a2, :a3, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :bct, :btr, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fvr, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :tad, :td, :trn, :usr, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 6
    ts = TSeries(1976M1, mvsales[201:350])
    xts = X13.series(ts, title="NORTHEAST ONE FAMILY Housing Starts")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    X13.regression!(spec, variables=[X13.ao(1976M2), X13.ao(1978M2), X13.ls(1980M2), X13.ls(1982M11), X13.ao(1984M2)], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,2,0,1,1))
    X13.forecast!(spec, maxlead=60, save=:all)
    X13.x11!(spec, seasonalma=:s3x9, title="Adjustment of 1 family housing starts", save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :a3, :ao, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :fct, :ftr, :fvr, :ira, :ls, :otl, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :rmx, :tad, :tal, :trn, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :ac2, :acf, :pcf, :sp0, :sp1, :sp2, :spr, :st0, :st1, :st2, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 7
    ts = TSeries(1976M1, mvsales[51:200])
    xts = X13.series(ts, title="Trend for NORTHEAST ONE FAMILY Housing Starts")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:auto, save=:all)
    X13.regression!(spec, variables=[X13.ls(1980M2), X13.ls(1982M11),], save=:all)
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.forecast!(spec, save=:all)
    X13.x11!(spec, type=:trend, trendma=13, sigmalim=[0.7, 1.0], title="Updated Dagum (1996) trend of 1 family housing starts", save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a19, :a3, :b1, :b11, :b13, :b17, :b2, :b20, :b3, :b6, :b7, :b8, :c1, :c11, :c13, :c17, :c2, :c20, :c4, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e7, :e8, :f1, :fct, :ftr, :fvr, :ls, :otl, :paf, :pe5, :pe7, :pe8, :pir, :psf, :rmx, :tad, :tal, :trn, :rrs)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :ac2, :acf, :pcf, :sp0, :spr, :st0, :str)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:est, :udg)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 8
    # TODO: re-enable after Census has helped with this example
    # ts = TSeries(1975M1, mvsales[251:350])
    # xts = X13.series(ts, title="Automobile sales", span=rangeof(ts))
    # spec = X13.newspec(xts)
    # # X13.transform!(spec, func=:log)
    # strike80 = TSeries(1975M1, zeros(length(ts)+12))
    # strike85 = TSeries(1975M1, zeros(length(ts)+12))
    # strike90 = TSeries(1975M1, zeros(length(ts)+12))
    # strike80[1980M1:1980M5] .= 1.0
    # # strike85[1985M5:1985M10] .= 1.0
    # # strike90[1990M7:1990M12] .= 1.0
    # strike85[1981M5:1981M10] .= 1.0
    # strike90[1982M7:1982M12] .= 1.0
    
    # X13.regression!(spec, variables=[:const], 
    #     data=MVTSeries(; strike80=strike80, strike85=strike85, strike90=strike90), 
    #     # data=MVTSeries(; strike80=strike80),  
    #     # data=strike90
    #     # data=MVTSeries(1970M1, [:strike80], hcat(collect(1.0:0.1:23.3) .^ 3)), 
    #     # data=MVTSeries(1970M1, [:strike80], hcat(collect(1.0:159.0))), 
    # )
    # X13.arima!(spec, X13.ArimaSpec(0,1,1), X13.ArimaSpec(0,1,1,12))
    # X13.x11!(spec, appendfcst=true, title="Car Sales in the US - Adjust for strikes in 80, 85, 90")
    # X13.x11regression!(spec, variables=:td)
    # res = X13.run(spec; verbose=false, load=:all);
    # println(collect(keys(res.series)))
    # println(collect(keys(res.tables)))
    # println(collect(keys(res.other)))
    # for key in (:a1, :a4d, :b10, :b11, :b13, :b14, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c14, :c16, :c2, :c4, :c5, :c6, :c7, :trn, :xrm)
    #     @test res.series[key] isa Union{TSeries,MVTSeries}
    # end
    # for key in (:rcm,)
    #     @test res.tables[key] isa AbstractWorkspace
    # end
    # for key in (:udg,)
    #     @test res.other[key] isa AbstractWorkspace
    # end

    # Manual example 9
    ts = TSeries(1978M1, rand2)
    xts = X13.series(ts, title="Total U.K. Retail Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:auto, aicdiff=0.0, save=:all)
    X13.x11!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Example with sigmavec
    ts = TSeries(1978M1, rand1)
    xts = X13.series(ts, title="Total U.K. Retail Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:auto, aicdiff=0.0, save=:all)
    X13.x11!(spec, calendarsigma=:select, sigmavec=[M1, M2, M12], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b17, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end
    
    # example with some pseudoadd output output
    ts = TSeries(1976M1, mvsales[1:250])
    spec = X13.newspec(ts)
    X13.x11!(spec; save=[:fsd, :fad], mode=:pseudoadd)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:fsd, :fad)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    
end

@testset "X13 x11regression run" begin

    # Manual example 1
    ts = TSeries(1976M1, mvsales[151:300])
    xts = X13.series(ts, title="Westus")
    spec = X13.newspec(xts)
    X13.x11!(spec; save=:all)
    X13.x11regression!(spec, variables=:td, save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b14, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c14, :c16, :c17, :c19, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :xrm)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rcm, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 2
    ts = TSeries(1976M1, mvsales[52:210]) #TODO: find out why this fails!
    ts = TSeries(1976M1, mvsales[53:211]) #TODO: find out why this works!
    ts = TSeries(1976M1, mvsales[51:250])
    xts = X13.series(ts, title="Westus")
    spec = X13.newspec(xts)
    X13.x11!(spec; save=:all)
    X13.x11regression!(spec, variables=:td, aictest=[:td, :easter], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c16, :c17, :c19, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :xrm)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rcm, :xoi, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 3
    ts = TSeries(1985M1, mvsales[101:150])
    xts = X13.series(ts, title="Ukclothes")
    spec = X13.newspec(xts)
    X13.x11!(spec; save=:all)
    # TODO: find out why this doesn't produce an error
    X13.x11regression!(spec, variables=:td, usertype=:holiday, critical=4.0,
        data=MVTSeries(1980M1, [:easter1, :easter2], hcat(collect(0.1:0.1:12.2),collect(12.2:-0.1:0.1))), save=:all
    )
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :bxh, :c1, :c10, :c11, :c13, :c16, :c17, :c19, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :xhl, :xrm)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rcm, :xoi, :sp0, :sp1, :sp2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 4
    ts = TSeries(1980M1, mvsales[251:350])
    xts = X13.series(ts, title="nzstarts")
    spec = X13.newspec(xts)
    X13.x11!(spec; save=:all)
    X13.x11regression!(spec, variables=:td, tdprior=[1.4, 1.4, 1.4, 1.4, 1.4, 0.0, 0.0], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :a4, :b1, :b10, :b11, :b13, :b14, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :c1, :c10, :c11, :c13, :c14, :c16, :c17, :c18, :c19, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :xrm)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end

    # Manual example 5
    ts = TSeries(1964Q1, mvsales[151:300])
    xts = X13.series(ts, title="MIDWEST ONE FAMILY Housing Starts", span=1964Q1:1989Q3)
    spec = X13.newspec(xts)
    X13.x11!(spec; save=:all)
    X13.x11regression!(spec, variables=[:td, X13.easter(8)],
        b=[0.4453, 0.8550, -0.3012, 0.2717, -0.1705, 0.0983, -0.0082],
        fixb=[true, true, true, true, true, true, false], save=:all
    )
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :bxh, :c1, :c10, :c11, :c13, :c16, :c17, :c19, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :xhl, :xrm)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rcm, :xoi)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end


    # Manual example 6
    ts = TSeries(1967M1, mvsales[101:400]) 
    xts = X13.series(ts, title="Motor Home Sales", span=X13.Span(1972M1))
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:x11default, sigmalim = [1.8, 2.8], appendfcst=true, save=:all)
    X13.x11regression!(spec, variables=[X13.td(1990M1), X13.easter(8), X13.labor(10), X13.thank(10)], save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    for key in (:a1, :b1, :b10, :b11, :b13, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :bxh, :c1, :c10, :c11, :c13, :c16, :c17, :c19, :c2, :c20, :c4, :c5, :c6, :c7, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :xhl, :xrm)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:d8b, :rcm, :xoi, :sp0, :sp1, :sp2, :st0, :st1, :st2)
        @test res.tables[key] isa AbstractWorkspace
    end
    for key in (:udg,)
        @test res.other[key] isa AbstractWorkspace
    end


    # Manual example 7
    #TODO: re-enable once Census has helped solve the issue.
    # ts = TSeries(1975M1, mvsales[51:100])
    # ts = TSeries(1975M1, mvsales[151:200])
    # xts = X13.series(ts, title="Automobile sales")
    # spec = X13.newspec(xts)
    # X13.transform!(spec, func=:log)
    # X13.regression!(spec, variables=[:const], 
    #     data=MVTSeries(1975M1, [:strike80, :strike85, :strike90], hcat(rand1[1:174],rand2[1:174],rand3[1:174])),
    # )
    # X13.arima!(spec, X13.ArimaSpec(0,1,1), X13.ArimaSpec(0,1,1,12))
    # X13.x11!(spec, title = ["Car Sales in US", "Adjusted for strikes in 80, 85, 90"])
    # X13.x11regression!(spec, variables=[:td, X13.easter(8)])
    # res = X13.run(spec; verbose=false, load=:all);
    # println(collect(keys(res.series)))
    # println(collect(keys(res.tables)))
    # println(collect(keys(res.other)))
    # for key in (:a1, :a18, :a4d, :b1, :b10, :b11, :b13, :b16, :b17, :b19, :b2, :b20, :b3, :b5, :b6, :b7, :b8, :bxh, :c1, :c10, :c11, :c13, :c16, :c17, :c2, :c20, :c4, :c5, :c6, :c7, :chl, :d1, :d10, :d11, :d12, :d13, :d16, :d18, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :e1, :e11, :e18, :e2, :e3, :e5, :e6, :e7, :e8, :f1, :paf, :pe5, :pe6, :pe7, :pe8, :pir, :psf, :tad, :trn, :xhl, :xrm, :fct, :ftr, :rrs)
    #     @test res.series[key] isa Union{TSeries,MVTSeries}
    # end
    # for key in (:d8b, :rcm, :xoi, :acf, :pcf, :sp0, :sp1, :sp2, :spr)
    #     @test res.tables[key] isa AbstractWorkspace
    # end
    # for key in (:est, :udg)
    #     @test res.other[key] isa AbstractWorkspace
    # end
 
end

@testset "X13 failed run" begin
    ts = TSeries(1976M1, mvsales[51:200])
    xts = X13.series(ts, title="Westus")
    spec = X13.newspec(xts)
    X13.x11!(spec; save=:all)
    X13.x11regression!(spec, variables=:td, aictest=[:td, :easter])
    @suppress @test_throws ErrorException X13.run(spec, verbose=false)

    ts = TSeries(1967Q1, mvsales[1:350])
    xts = X13.series(ts, title="Quarterly stock prices on NASDAQ")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=:s3x9)
    X13.slidingspans!(spec, length=40, numspans=3)
    @suppress @test_throws ErrorException res = X13.run(spec; verbose=false, load=:all);

end

@testset "X13 using a string" begin
    ts = TSeries(1950Q1, mvsales[1:150])
    xts = X13.series(ts, title="Quarterly Grape Harvest")
    spec = X13.newspec(xts)
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.estimate!(spec; save=:all)
    X13.x13write(spec)
    res = X13.run(spec.string, Quarterly; verbose=false, load=:all);
    @test res isa X13.X13result
    for key in (:a1, :a3, :b1, :ref, :rrs, :rsd)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :ac2, :acf, :pcf)
        @test res.tables[key] isa X13.WorkspaceTable
    end
end

@testset "X13 with missing values" begin
    missing_ts = TSeries(1990Q1, Float64.(mvsales[1:150]))
    missing_ts[1994Q1:1994Q4] .= NaN
    @suppress @test_throws ArgumentError xts = X13.series(missing_ts, title="Quarterly Grape Harvest")

    xts = X13.series(missing_ts, title="Quarterly Grape Harvest", missingcode = -99999.0)
    spec = X13.newspec(xts)
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.estimate!(spec; save=:all)
    X13.x13write(spec)
    res = X13.run(spec, verbose=false, load=:all);
    @test res isa X13.X13result
    for key in (:a1, :a3, :b1, :ref, :rrs, :rsd, :mv)
        @test res.series[key] isa Union{TSeries,MVTSeries}
    end
    for key in (:itr, :ac2, :acf, :pcf)
        @test res.tables[key] isa X13.WorkspaceTable
    end
end


@testset "X13 deseasonalize" begin
    ts = TSeries(1967M1, Float64.(mvsales[101:400])) 
    ts2 = X13.deseasonalize(ts)
    @test ts2 isa TSeries
    @test rangeof(ts2) == rangeof(ts)
    @test ts2 == X13.deseasonalize!(ts)
end

@testset "X13 misc" begin
    dict = OrderedDict{Symbol,Any}()
    push!(dict, :numbers => [1,2,3,4])
    push!(dict, :words => ["one","two","three","four"])
    # dict[:words] = ["one","two","three","four"]

    wst1 = X13.WorkspaceTable(dict)
    wst2 = X13.WorkspaceTable(; numbers = [1,2,3,4], words = ["one","two","three","four"])
    wst3 = X13.WorkspaceTable()
    wst3.numbers =  [1,2,3,4]
    wst3.words = ["one","two","three","four"]

    @test keys(wst1) == keys(wst2)
    for key in keys(wst1)
        @test wst1[key] == wst2[key]
    end
    @test keys(wst2) == keys(wst3)
    for key in keys(wst2)
        @test wst2[key] == wst3[key]
    end

    let io = IOBuffer()
        show(IOContext(io, :displaysize => (20, 80)), MIME"text/plain"(), wst1)
        @test length(readlines(seek(io, 0))) == 6
        @test readlines(seek(io, 0)) == ["numbers  words ", "-------- ------", "       1 one   ", "       2 two   ", "       3 three ", "       4 four  "]
    end
    let io = IOBuffer()
        wst4 = X13.WorkspaceTable()
        show(IOContext(io, :displaysize => (20, 80)), MIME"text/plain"(), wst4)
        @test startswith(readlines(seek(io, 0))[1], "Empty")
    end

    # printing a large WorkspaceTable
    wst5 = X13.WorkspaceTable()
    for i in 1:100
        wst5[Symbol("var$i")] = randn(100)
    end

    let io = IOBuffer()
        show(IOContext(io, :displaysize => (20, 80)), MIME"text/plain"(), wst5)
        @test length(readlines(seek(io, 0))) <= 20
        lines = readlines(seek(io, 0))
        @test maximum(length.(lines)) <= 80
        @test contains(lines[10], "⋮")
    end


    # get descriptions
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    X13.arima!(spec, X13.ArimaModel(2,1,0,0,1,1))
    X13.estimate!(spec; save=:all)
    res = X13.run(spec; verbose=false, load=:all);
    desc = X13.descriptions(res)
    @test keys(res.series) == keys(desc.series)
    @test desc.series.a1 == "SERIES: time series data, with associated dates (if the span argument is present, data are printed and/or saved only for the specified span)"
    @test desc.tables.acm == "ESTIMATE: correlation matrix of ARMA parameter estimates if used with the print argument; covariance matrix of same if used with the save argument"
    
    # lazy-loading
    ts = TSeries(1976M1, mvsales[1:50])
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log, save=:all)
    X13.arima!(spec, X13.ArimaModel(2,1,0,0,1,1))
    X13.estimate!(spec; save=:all)
    res = X13.run(spec; verbose=false);
    @test res.series.a1 isa TSeries
    @test res.tables.acm isa X13.WorkspaceTable
    @test res.text.err isa String
    @test res.text.out isa String
    @test res.text.spc isa String
    @test res.text.gmt isa String
   
end

