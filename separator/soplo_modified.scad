// Важно: для глобальных констант нужен include (use не импортирует переменные)
include <common_params.scad>;
use <adapter_plate_common.scad>;

$fn = 96;

// Тонкое сечение для сшивки стыков (hull между двумя дисками).
module stitch_disk(d, h) {
    cylinder(h = h, d = d, center = true);
}

module bend_y_transition(d_start, d_end, radius, angle, end_x_shift = 0, segments = 24) {
    for (i = [0 : segments - 1]) {
        hull() {
            bend_y_section(i / segments, d_start, d_end, radius, angle, end_x_shift);
            bend_y_section((i + 1) / segments, d_start, d_end, radius, angle, end_x_shift);
        }
    }
}

module bend_y_section(t, d_start, d_end, radius, angle, end_x_shift = 0) {
    a = angle * t;
    d = d_start + (d_end - d_start) * t;
    s = 3 * t * t - 2 * t * t * t;
    x = radius * (1 - cos(a)) - end_x_shift * s;
    translate([x, 0, radius * sin(a)])
    rotate([0, a, 0])
    cylinder(h = 0.8, d = d, center = true);
}

module bend_x_constant(d, radius, angle, segments = 24) {
    for (i = [0 : segments - 1]) {
        hull() {
            bend_x_section(i / segments, d, radius, angle);
            bend_x_section((i + 1) / segments, d, radius, angle);
        }
    }
}

module bend_x_section(t, d, radius, angle) {
    a = angle * t;
    translate([0, -radius * (1 - cos(a)), radius * sin(a)])
    rotate([a, 0, 0])
    cylinder(h = 0.8, d = d, center = true);
}

function v_add(a, b) = [a[0] + b[0], a[1] + b[1], a[2] + b[2]];

function dir_yx(t, a_start_y, a_end_x) =
    let(ax = a_end_x * t, ay = a_start_y * (1 - t))
    [sin(ay) * cos(ax), -sin(ax), cos(ay) * cos(ax)];

function path_yx_steps(step_idx, total_steps, step_len, a_start_y, a_end_x) =
    step_idx <= 0
    ? [0, 0, 0]
    : let(
        prev = path_yx_steps(step_idx - 1, total_steps, step_len, a_start_y, a_end_x),
        t = (step_idx - 0.5) / total_steps,
        d = dir_yx(t, a_start_y, a_end_x)
    )
    v_add(prev, [d[0] * step_len, d[1] * step_len, d[2] * step_len]);

function path_yx_point(t, arc_len, a_start_y, a_end_x, total_steps = 40) =
    let(
        steps = t <= 0 ? 0 : (t >= 1 ? total_steps : floor(t * total_steps)),
        step_len = arc_len / total_steps
    )
    path_yx_steps(steps, total_steps, step_len, a_start_y, a_end_x);

module bend_yx_transition(d, arc_len, a_start_y, a_end_x, segments = 24, path_steps = 40) {
    for (i = [0 : segments - 1]) {
        hull() {
            bend_yx_section(i / segments, d, arc_len, a_start_y, a_end_x, path_steps);
            bend_yx_section((i + 1) / segments, d, arc_len, a_start_y, a_end_x, path_steps);
        }
    }
}

module bend_yx_section(t, d, arc_len, a_start_y, a_end_x, path_steps) {
    p = path_yx_point(t, arc_len, a_start_y, a_end_x, path_steps);
    ax = a_end_x * t;
    ay = a_start_y * (1 - t);
    translate(p)
    rotate([ax, ay, 0])
    cylinder(h = 0.8, d = d, center = true);
}


module adapter_plate(
// Основные размеры кольца
outer_diameter = ADAPTER_OUTER_D_120,      // внешний диаметр пластины, мм
inner_diameter = ADAPTER_INNER_D_86,       // внутренний диаметр (проходное отверстие), мм
plate_thickness = ADAPTER_PLATE_TH_10,     // толщина пластины, мм

// Параметры ушей (креплений)
num_ears = ADAPTER_NUM_EARS_4, // количество ушей
ear_diameter = EAR_D_22,       // диаметр круглого уха, мм
bolt_hole_diameter = EAR_BOLT_D_6_5,  // диаметр отверстия под M5, мм
bolt_distance_from_center = EAR_BOLT_R_56_56, // расстояние от центра до центра болта, мм

// Желобок для резинки
groove_circle_radius = GROOVE_R_49,  // радиус окружности желобка, мм
groove_diameter = GROOVE_D_2,        // ширина канавки, мм
groove_depth = GROOVE_DEPTH_1        // глубина канавки, мм
) {
    adapter_plate_base(
        outer_diameter = outer_diameter,
        inner_diameter = inner_diameter,
        plate_thickness = plate_thickness,
        num_ears = num_ears,
        ear_diameter = ear_diameter,
        bolt_hole_diameter = bolt_hole_diameter,
        bolt_distance_from_center = bolt_distance_from_center,
        groove_circle_radius = groove_circle_radius,
        groove_diameter = groove_diameter+1,
        groove_depth = groove_depth+1,
        tube_diameter = D_BRANCH_OUT_67
    );
}

module tube(
d1=ADAPTER_INNER_D_61,
d2=D_EXIT_44,
d3=40,
l1=20,
l2=50,
l3=120,
l4=20,
x1_shift=3,
joint_overlap=0.2,
stitch_h=0.5,
a1=11,
a2=20,
r2=40, // длина плавного перехода 3->4
segments=24
)
{
    // Первый плавный переход заменяет старый конус l2.
    // Делаем дугу с длиной по оси ~= l2.
    r1 = a1 == 0 ? 0 : l2 / (a1 * PI / 180);
    x1_geom = r1 * (1 - cos(a1));
    x1_comp = x1_geom - x1_shift;
    z1 = r1 * sin(a1);
    x_mid = x1_shift + l3 * sin(a1);
    z_mid = l1 + z1 + l3 * cos(a1);
    p2 = path_yx_point(1, r2, a1, a2, max(segments, 40));
    x2 = x_mid + p2[0];
    y2 = p2[1];
    z2 = z_mid + p2[2];
    ps = max(segments, 40);



    // Стык 1: прямая l1 -> первое сглаживание
    hull() {
        cylinder(h = l1, d = d1, center = false);
        translate([0, 0, l1])
        bend_y_section(0, d1, d2, r1, a1, x1_comp);
    }

    translate([0, 0, l1])
    bend_y_transition(
        d_start = d1,
        d_end = d2,
        radius = r1,
        angle = a1,
        end_x_shift = x1_comp,
        segments = segments
    );

    // Стык 2: первое сглаживание -> прямая l3
    hull() {
        translate([0, 0, l1])
        bend_y_section(1, d1, d2, r1, a1, x1_comp);
        translate([x1_shift, 0, l1 + z1])
        rotate([0, a1, 0])
        cylinder(h = l3, d = d2, center = false);

        translate([x_mid, 0, z_mid])
        bend_yx_section(0, d2, r2, a1, a2, ps);
    }

    translate([x_mid, 0, z_mid])
    bend_yx_transition(
        d = d2,
        arc_len = r2,
        a_start_y = a1,
        a_end_x = a2,
        segments = segments,
        path_steps = ps
    );

    // Стык 4: второе сглаживание -> последняя труба
    hull() {
        translate([x_mid, 0, z_mid])
        bend_yx_section(1, d2, r2, a1, a2, ps);
    translate([x2, y2, z2])
    rotate([a2, 0, 0])
    translate([0, 0, -joint_overlap])
    cylinder(h = l4 + joint_overlap, d1 = d2, d2 = d3, center = false);
    }

}
rotate([0,0,15])
adapter_plate(outer_diameter = ADAPTER_OUTER_D_90,
inner_diameter = ADAPTER_INNER_D_61,
groove_circle_radius = GROOVE_R_38,
bolt_distance_from_center = EAR_BOLT_R_45
); 
difference(){
    eps = 0.05;
    tube(d1=D_BRANCH_OUT_67,d2=D_EXIT_50, d3=46, a2=-20);
    translate([0,0,-eps])
    tube(l4=41, a2=-20); // по умолчанию D1=61, D2=44
/*    rotate([0,0,15]);
    translate([0,0,20+50+10+95/2])
    rotate([0,atan(95/50),15])
    translate([-250,-250,0])
    cube([500,500,500]);*/
}
