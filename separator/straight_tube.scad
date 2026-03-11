use <common_params.scad>;
use <adapter_plate_common.scad>;

$fn = 96;


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
        groove_diameter = groove_diameter,
        groove_depth = groove_depth
    );
}

module tube(
d1=ADAPTER_INNER_D_61,
d2=D_EXIT_44,
l1=20,
l2=50,
l3=120
)
{
    cylinder(l1, d=d1,center = false);
    translate([0,0,l1])
    cylinder(h=l2, d1 = d1, d2= d2, center = false);
    translate([0,0,l1+l2])
    cylinder(h = l3, d = d2, center = false);
    
}

adapter_plate(outer_diameter = ADAPTER_OUTER_D_90,
inner_diameter = ADAPTER_INNER_D_61,
groove_circle_radius = GROOVE_R_38,
bolt_distance_from_center = EAR_BOLT_R_45
); 
difference(){
    tube(d1=D_BRANCH_OUT_67,d2=D_EXIT_50);
    tube(); // по умолчанию D1=61, D2=44
}
