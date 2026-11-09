// YE660D / YE-62M 白色气插头，估算版 v1。单位 mm。
// 仅供关机试配。未经原件实测、气密及测量性能验证。
// 主机插杆取 5 mm 作为照片缩放基准：照片中插杆宽约 10 px，
// 插杆长约 28 px，台肩宽约 19 px、长约 26 px。
// 软管端、通孔和所有倒角均为设计假设。
plug_d = 5.0;
plug_len = 14.0;
collar_d = 9.5;
collar_len = 13.0;
hose_root_d = 4.2;
hose_barb_d = 4.8;
hose_tip_d = 3.8;
hose_len = 10.0;
bore_d = 2.0;
$fn = 128;

collar_end = plug_len + collar_len;
end_z = collar_end + hose_len;
assert(bore_d > 0 && bore_d < min(plug_d-0.6, hose_root_d, hose_tip_d));
assert(collar_d-0.8 > max(plug_d, hose_barb_d) && hose_barb_d > hose_root_d);
assert(plug_len > 0.5 && collar_len > 1 && hose_len > 0);

// 半剖面绕 z 轴旋转。主机端 z=0，软管端 z=end_z。
stations = [
    [0, plug_d-0.6], [0.45, plug_d], [plug_len, plug_d],
    [plug_len, collar_d-0.8], [plug_len+0.4, collar_d],
    [collar_end-0.4, collar_d], [collar_end, collar_d-0.8],
    [collar_end, hose_root_d],
    [collar_end+0.18*hose_len, hose_root_d],
    [collar_end+0.22*hose_len, hose_barb_d],
    [collar_end+0.45*hose_len, hose_root_d],
    [collar_end+0.56*hose_len, hose_root_d],
    [collar_end+0.60*hose_len, hose_barb_d],
    [collar_end+0.85*hose_len, hose_root_d],
    [end_z, hose_tip_d]
];
rotate_extrude()
    polygon(concat([for (s = stations) [s[1]/2, s[0]]],
                   [[bore_d/2, end_z], [bore_d/2, 0]]));
