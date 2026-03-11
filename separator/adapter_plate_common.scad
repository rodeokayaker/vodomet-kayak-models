// Общее адаптерное кольцо на базе реализации из straightener140.scad

use <common_params.scad>;

module adapter_plate_base(
    // Основные размеры кольца
    outer_diameter = ADAPTER_OUTER_D_120,      // внешний диаметр пластины, мм
    inner_diameter = ADAPTER_INNER_D_86,       // внутренний диаметр (проходное отверстие), мм
    plate_thickness = ADAPTER_PLATE_TH_10,     // толщина пластины, мм

    // Параметры ушей (креплений)
    num_ears = ADAPTER_NUM_EARS_4,             // количество ушей
    ear_diameter = EAR_D_22,                   // диаметр круглого уха, мм
    bolt_hole_diameter = EAR_BOLT_D_6_5,       // диаметр отверстия под M5, мм
    bolt_distance_from_center = EAR_BOLT_R_56_56, // расстояние от центра до центра болта, мм

    // Желобок для резинки (прямоугольный профиль, как в straightener140.scad)
    groove_circle_radius = GROOVE_R_49,        // радиус окружности желобка, мм
    groove_diameter = GROOVE_D_2,              // «диаметр» канавки (ширина прямоугольника), мм
    groove_depth = GROOVE_DEPTH_1_8,           // глубина канавки (радиальный размер), мм

    // Детализация
    $fn_ring = 100,
    $fn_ear  = 80,
    $fn_bolt = 50
) {
    difference() {
        union() {
            // Основное кольцо с пластиной
            cylinder(h = plate_thickness, r = outer_diameter/2, center = false, $fn = $fn_ring);
            
            // Уши для крепления
            for (i = [0 : num_ears - 1]) {
                angle = i * 360 / num_ears;
                translate([
                    bolt_distance_from_center * cos(angle),
                    bolt_distance_from_center * sin(angle),
                    0
                ]) {
                    cylinder(h = plate_thickness, r = ear_diameter/2, center = false, $fn = $fn_ear);
                }
            }
        }
        
        // Вырез внутреннего отверстия
        cylinder(h = plate_thickness + 2, r = inner_diameter/2, center = false, $fn = $fn_ring);
        
        // Отверстия под болты M5
        for (i = [0 : num_ears - 1]) {
            angle = i * 360 / num_ears;
            translate([
                bolt_distance_from_center * cos(angle),
                bolt_distance_from_center * sin(angle),
                0
            ]) {
                cylinder(h = plate_thickness + 2, r = bolt_hole_diameter/2, center = false, $fn = $fn_bolt);
            }
        }
        
        // Желобок для резинки (прямоугольный паз, как в straightener140.scad)
        rotate_extrude(convexity = 10) {
            translate([groove_circle_radius - groove_depth, -groove_diameter/2, 0])
            square([groove_depth, groove_diameter], center = false);
        }
    }
}

