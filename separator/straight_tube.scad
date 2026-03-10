$fn = 96;


module adapter_plate(
// Основные размеры кольца
outer_diameter = 120,      // внешний диаметр пластины, мм
inner_diameter = 86,       // внутренний диаметр (проходное отверстие), мм
plate_thickness = 10,      // толщина пластины, мм

// Параметры ушей (креплений)
num_ears = 4,              // количество ушей
ear_diameter = 22,         // диаметр круглого уха, мм
bolt_hole_diameter = 6.5,  // диаметр отверстия под M5, мм
bolt_distance_from_center = 56.56, // расстояние от центра до центра болта, мм

// Желобок для резинки
groove_circle_radius = 49,  // радиус окружности желобка, мм
groove_diameter = 2,        // диаметр полукруглого желобка, мм
groove_depth = 1           // глубина желобка (радиус), мм
) {
    difference() {
        union() {
            // Основное кольцо с пластиной
            cylinder(h = plate_thickness, r = outer_diameter/2, center = false, $fn = 100);
            
            // Уши для крепления
            for (i = [0 : num_ears - 1]) {
                angle = i * 360 / num_ears;
                translate([
                    bolt_distance_from_center * cos(angle),
                    bolt_distance_from_center * sin(angle),
                    0
                ]) {
                    cylinder(h = plate_thickness, r = ear_diameter/2, center = false, $fn = 80);
                }
            }
        }
        
        // Вырез внутреннего отверстия
        cylinder(h = plate_thickness + 2, r = inner_diameter/2, center = false, $fn = 100);
        
        // Отверстия под болты M5
        for (i = [0 : num_ears - 1]) {
            angle = i * 360 / num_ears;
            translate([
                bolt_distance_from_center * cos(angle),
                bolt_distance_from_center * sin(angle),
                0
            ]) {
                cylinder(h = plate_thickness + 2, r = bolt_hole_diameter/2, center = false, $fn = 50);
            }
        }
        
        // Желобок для резинки (полукруглый паз)
        // Создаём паз по окружности радиусом 50 мм
        rotate_extrude(convexity = 10) {
            translate([groove_circle_radius, 0, 0]) 
            circle(r = groove_diameter/2);
        }
        

    }
    
    // Добавляем скругления на ушах (декоративное уточнение геометрии)
    // OpenSCAD имеет ограничения с филе, но можно использовать Minkowski
}

module tube(
d1=61,
d2=44,
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

adapter_plate(outer_diameter = 90,      
inner_diameter = 61,  
groove_circle_radius = 38,
bolt_distance_from_center = 45
); 
difference(){
    tube(d1=67,d2=50);
    tube();
}
