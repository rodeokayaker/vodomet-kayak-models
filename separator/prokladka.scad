include <common_params.scad>;
use <adapter_plate_common.scad>;

$fn = 96;
module prokladka(
// Основные размеры кольца
outer_diameter = ADAPTER_OUTER_D_120,      // внешний диаметр пластины, мм
inner_diameter = ADAPTER_INNER_D_86,       // внутренний диаметр (проходное отверстие), мм
plate_thickness = 1.5,     // толщина пластины, мм

// Параметры ушей (креплений)
num_ears = ADAPTER_NUM_EARS_4, // количество ушей
ear_diameter = EAR_D_22,       // диаметр круглого уха, мм
bolt_hole_diameter = EAR_BOLT_D_6_5,  // диаметр отверстия под M5, мм
bolt_distance_from_center = EAR_BOLT_R_56_56, // расстояние от центра до центра болта, мм

        groove_circle_radius = GROOVE_R_49,
        groove_diameter = GROOVE_D_2,



    // Конический переход
    transit_height = ADAPTER_PLATE_TH_10 * 2,
    transit_width = 3*2,
    tube_diameter = ADAPTER_INNER_D_86

) {
    // Используем универсальную реализацию адаптерного кольца.
    adapter_plate_base(
        outer_diameter = outer_diameter-2,
        inner_diameter = inner_diameter+1,
        plate_thickness = plate_thickness,

        num_ears = num_ears,
        ear_diameter = ear_diameter-2,
        bolt_hole_diameter = bolt_hole_diameter+4,
        bolt_distance_from_center = bolt_distance_from_center,

        groove_circle_radius = groove_circle_radius,
        groove_diameter = groove_diameter,
        groove_depth = 0,

        bolt_head_diameter = 10,
        bolt_head_depth =0,
        ear_thickness = plate_thickness,
        transit_height = 0,
        transit_width = 0,
        tube_diameter = tube_diameter
    );
    

        rotate_extrude(convexity = 10, $fn=96) {
            translate([groove_circle_radius, 0, 0]) 
            circle(r = groove_diameter/2-0.1);
        }
}

prokladka(
groove_diameter = 0);
/*prokladka(outer_diameter = ADAPTER_OUTER_D_90,
inner_diameter = ADAPTER_INNER_D_61,
groove_circle_radius = GROOVE_R_38,
bolt_distance_from_center = EAR_BOLT_R_45,
groove_diameter = 0

);*/ 
