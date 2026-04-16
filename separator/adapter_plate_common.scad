// Общее адаптерное кольцо на базе реализации из straightener140.scad

// Важно: для глобальных констант нужен include (use не импортирует переменные)
include <common_params.scad>;

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

    // Углубление под шляпку болта со стороны, где нет желобка
    bolt_head_diameter = 10,   // диаметр шляпки, мм
    bolt_head_depth = 4,       // глубина углубления от верхней плоскости пластины, мм

    // Толщина уха (и логичного утолщения сектора кольца).
    // По умолчанию: чуть толще, чем сама пластина.
    ear_thickness = undef,

    // Конический переход
    transit_height = ADAPTER_PLATE_TH_10,
    transit_width = 3,
    tube_diameter = ADAPTER_INNER_D_86 + 6,

    // Детализация
    $fn_ring = 100,
    $fn_ear  = 80,
    $fn_bolt = 50,
    $fn_head = 60
) {
    // Некоторые версии OpenSCAD не видят значения по умолчанию одного параметра
    // при ссылке на другой параметр в выражении дефолта. Поэтому дефолт считаем внутри.
    ear_thickness_eff = is_undef(ear_thickness) ? plate_thickness + 2 : ear_thickness;

    // Геометрия "продолжения" уха в кольцо: полукруг (берется самим цилиндром уха)
    // и прямоугольное продолжение в сторону центра (будет объединением с цилиндром уха).
    ear_r = ear_diameter / 2;
    xLen = bolt_distance_from_center; // идем до центра, внутренность вырежется дальше

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
                    cylinder(h = ear_thickness_eff, r = ear_diameter/2, center = false, $fn = $fn_ear);
                }
            }

            // Логичное продолжение утолщения на основном кольце:
            // прямоугольник (в локальной системе уха) + цилиндр уха = требуемый профиль.
            for (i = [0 : num_ears - 1]) {
                angle = i * 360 / num_ears;
                c = cos(angle);
                s = sin(angle);

                // В локальной системе:
                // - ось X направлена к центру кольца
                // - ось Y тангенциальная
                // Прямоугольник: x=[0..xLen], y=[-ear_r..+ear_r]
                // Квадрат задаем в глобальных координатах:
                // ear_center = [d*c, d*s], d=bolt_distance_from_center
                d = bolt_distance_from_center;
                k = d - xLen;

                p1 = [d * c - s * ear_r, d * s + c * ear_r];     // y=-ear_r, x=0
                p2 = [d * c + s * ear_r, d * s - c * ear_r];     // y=+ear_r, x=0
                p3 = [c * k + s * ear_r, s * k - c * ear_r];     // y=+ear_r, x=xLen
                p4 = [c * k - s * ear_r, s * k + c * ear_r];     // y=-ear_r, x=xLen

                // Ограничиваем добавку снаружи внешним радиусом кольца,
                // чтобы не вылезать за прежнюю внешнюю геометрию на верхней высоте.
                intersection() {
                    translate([0, 0, plate_thickness])
                        linear_extrude(height = ear_thickness_eff - plate_thickness)
                            polygon([p1, p2, p3, p4]);

                    translate([0, 0, plate_thickness])
                        cylinder(
                            h = ear_thickness_eff - plate_thickness,
                            r = outer_diameter / 2,
                            center = false,
                            $fn = $fn_ring
                        );
                }
            }
            translate([0,0, plate_thickness])
            cylinder(h = transit_height, r1 = tube_diameter/2 + transit_width, r2=tube_diameter/2, center = false, $fn=$fn_ring);
        }
        
        // Вырез внутреннего отверстия
        cylinder(h = ear_thickness_eff + 2+transit_height, r = inner_diameter/2, center = false, $fn = $fn_ring);
        
        // Отверстия под болты M5
        for (i = [0 : num_ears - 1]) {
            angle = i * 360 / num_ears;
            translate([
                bolt_distance_from_center * cos(angle),
                bolt_distance_from_center * sin(angle),
                0
            ]) {
                cylinder(h = ear_thickness_eff + 2, r = bolt_hole_diameter/2, center = false, $fn = $fn_bolt);
            }
        }

        // Углубления под шляпки болтов (со стороны верхней поверхности платы)
        for (i = [0 : num_ears - 1]) {
            angle = i * 360 / num_ears;
            translate([
                bolt_distance_from_center * cos(angle),
                bolt_distance_from_center * sin(angle),
                ear_thickness_eff - bolt_head_depth
            ]) {
                // bolt_head_diameter интерпретируем как размер под ключ (по плоскостям),
                // а cylinder.d задает описанную окружность -> переводим.
                hex_circ_d = bolt_head_diameter / cos(30);
                cylinder(h = bolt_head_depth, d = hex_circ_d, center = false, $fn = 6);
            }
        }
        
        // Желобок для резинки (прямоугольный паз, как в straightener140.scad)
        rotate_extrude(convexity = 10) {
            translate([groove_circle_radius - groove_depth, -groove_diameter/2, 0])
            square([groove_depth, groove_diameter], center = false);
        }
    }
}

