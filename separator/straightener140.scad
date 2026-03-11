// Модуль остановки вращения водного потока в вертикальной трубе
// Крыльчатка с 7 лопастями:
// - Первая половина высоты: угол меняется от -45° до 0° по закону ease-out (изгиб)
// - Вторая половина высоты: лопасти вертикальные (0°) для выравнивания потока
// - Профиль: прямой прямоугольный, толщина 1.5 мм
// - Направление вращения: противоположное (отрицательный угол)
//
// ПАРАМЕТРЫ:
// - D_tube_inner: внутренний диаметр трубы (86 мм)
// - D_hub_bottom: диаметр ступицы внизу (30 мм)
// - H_blade: высота крыльчатки/лопастей (100 мм)
// - H_hub: высота ступицы (110 мм, выступает на 10 мм выше лопастей)
// - N_blades: количество лопастей (7)
// - thickness_max: толщина прямого профиля (1.5 мм)
// - angle_start: начальный угол лопастей внизу (-45° для противоположного вращения)
// - angle_end: конечный угол лопастей вверху (0° - вертикально)
//
// КОНСТРУКЦИЯ:
// - Лопасти имеют прямой прямоугольный профиль толщиной 1.5 мм
// - Угол наклона меняется по закону ease-out в первой половине высоты (от 45° до 0°)
//   Во второй половине лопасти вертикальные (0°) для выравнивания потока
// - Лопасти радиальные (прямые в горизонтальном разрезе)
// - Ступица коническая: от 30 мм внизу до 0 мм вверху
// - Лопасти крепятся к ступице и к стенке трубы (вплотную)
//
// НАПРАВЛЕНИЕ ПОТОКА:
// - Поток движется снизу вверх (по оси Z)
// - Вращение потока: против часовой стрелки при взгляде сверху
//   (по часовой при взгляде снизу вверх)
// - Лопасти наклонены против направления вращения для его остановки
//
// ИСПОЛЬЗОВАНИЕ:
//   use <flow_straightener.scad>
//   flow_straightener();
//
//   Или с параметрами:
//   flow_straightener_assembly(
//       D_tube = 86,
//       D_hub = 30,
//       H_blade_height = 100,
//       H_hub_height = 110,
//       N = 7,
//       thickness = 1.5,
//       angle_start_deg = -45,
//       angle_end_deg = 0
//   );
$fn = 96;

// Общие параметры
use <common_params.scad>;
use <flow_straightener_core.scad>;
use <adapter_plate_common.scad>;

// Параметры
D_tube_inner = D_TUBE_IN_88;        // Внутренний диаметр трубы, мм
D_hub_bottom = D_HUB_BOTTOM_30;     // Диаметр ступицы внизу, мм
H_blade = H_BLADE_100;              // Высота крыльчатки (лопастей), мм
H_hub = H_HUB_110;                  // Высота ступицы, мм
N_blades = 7;                       // Количество лопастей
thickness_max = TH_BLADE_1_5;       // Толщина прямого профиля, мм
angle_start = ANGLE_BLADE_START_NEG_30; // Начальный угол лопастей, градусы (отрицательный для противоположного вращения)
angle_end = ANGLE_BLADE_END_0;      // Конечный угол лопастей, градусы

// Радиусы
R_outer = D_tube_inner / 2;      // Внешний радиус (к стенке трубы)
R_inner_bottom = D_hub_bottom / 2; // Внутренний радиус внизу (к ступице)

// Посадка подшипника 608
bearing_od = BEARING608_OD;          // наружный диаметр
bearing_id = BEARING608_ID;          // внутренний диаметр
bearing_w  = BEARING608_W;           // ширина
bearing_fit = BEARING608_FIT;        // зазор под печать (0.1..0.25)
bearing_shoulder = BEARING608_SHOULDER;   // упор подшипника снизу/сверху


// Модуль для создания прямого профиля (прямоугольного)
// chord - длина хорды (радиально от ступицы к стенке)
// thickness - толщина профиля (тангенциально, вокруг окружности)
// height - высота профиля (вдоль оси трубы)
module straight_profile(chord=50, thickness=1.5, height=0.001) {
    translate([0, -thickness/2, 0])
    linear_extrude(height, center=false)
    polygon([[0,0],[0,thickness],[chord,thickness],[chord,0]]);
//    cube([chord, thickness, height]);
}

// Модуль одной лопасти
module flow_straightener_blade(
    R_outer = R_outer,
    R_inner_bottom = R_inner_bottom,
    H = H_blade,
    angle_start = angle_start,
    angle_end = angle_end,
    thickness_max = thickness_max,
    steps = 180
) {
    // Максимальная длина хорды (внизу, где ступица максимальная)
    max_chord = R_outer - R_inner_bottom;
    
    for (i = [0:steps-1]) {
        t = i / steps;
        t_next = (i + 1) / steps;
        
        z1 = t * H;
        z2 = t_next * H;
        
        // Угол меняется только в первой половине высоты (от 45° до 0°)
        // Во второй половине лопасти вертикальные (0°) для выравнивания потока
        H_bend = H *2/3;  // Высота зоны изгиба (первая половина)
        
        // Нормализованная координата для зоны изгиба (0..1 в первой половине)
        t_bend1 = min(1, z1 / H_bend);
        t_bend2 = min(1, z2 / H_bend);
        
        // Угол: ease-out в первой половине, 0° во второй половине
        angle1 = z1 < H_bend ? 
            ease_out_angle(t_bend1, angle_start, angle_end) : 
            angle_end;
        angle2 = z2 < H_bend ? 
            ease_out_angle(t_bend2, angle_start, angle_end) : 
            angle_end;
        
        // Радиус ступицы на текущей высоте (линейная интерполяция)
        R_inner1 = max(0, R_inner_bottom * (1 - z1 / H_hub) - 2);
        R_inner2 = max(0, R_inner_bottom * (1 - z2 / H_hub) - 2);
        
        // Длина хорды на данном уровне
        // Лопасть идет от ступицы к стенке под углом angle от радиального направления
        // Реальная длина хорды больше, чем радиальное расстояние из-за наклона
        // Но для упрощения используем радиальное расстояние как приближение
        // (точный расчет требует учета угла наклона)
        chord1 = R_outer - R_inner1;
        chord2 = R_outer - R_inner2;
        
        // Для прямого профиля толщина постоянная (1.5 мм), не зависит от хорды
        
        // Создаём прямой профиль на каждом уровне
        // Профиль - прямоугольник: хорда идет от ступицы к стенке, толщина постоянная
        // Трансформации:
        // 1. straight_profile создает прямоугольник: хорда по X, толщина по Y, высота по Z
        // 2. rotate([90, 0, 0]): поворачиваем так, чтобы толщина шла по Z (вверх по трубе)
        // 3. translate([R_inner1, 0, 0]): перемещаем начало профиля к ступице
        // 4. rotate([0, 0, angle1]): поворачиваем на угол наклона (вокруг Z)
        // 5. translate([0, 0, z1]): перемещаем на нужную высоту
        
        // Толщина профиля на уровнях z1 и z2 (как в straight_profile)
        th1 = min(thickness_max, (H - z1) / 20 + 0.4, z1 / 5 + 0.4);
        th2 = min(thickness_max, (H - z2) / 20 + 0.4, z2 / 5 + 0.4);
        
        a1 = angle1 ;// * 0.01745329252;
        a2 = angle2 ;//* 0.01745329252;
        // 4 угла профиля в локальных координатах (straight_profile: хорда X, толщина Y)
        lo1 = [[0, 0 /*-th1/2*/], [chord1, 0/*-th1/2*/], [chord1, th1/*/2*/], [0, th1/*/2*/]];
        lo2 = [[0, 0/*-th2/2*/], [chord2, 0/*-th2/2*/], [chord2, th2/*/2*/], [0, th2/*/2*/]];
        points = [
            for (k = [0:3]) blade_point_world(lo1[k], R_inner1, cos(a1), sin(a1), z1),
            for (k = [0:3]) blade_point_world(lo2[k], R_inner2, cos(a2), sin(a2), z2)
        ];
        // Треугольные грани (четырёхугольники некомпланарны при разных chord/th/angle)
        faces = [
            [0, 3, 2], [0, 2, 1],       // низ
            [4, 5, 6], [4, 6, 7],       // верх
            [0, 1, 5], [0, 5, 4],       // бок 0
            [1, 2, 6], [1, 6, 5],       // бок 1
            [2, 3, 7], [2, 7, 6],       // бок 2
            [3, 0, 4], [3, 4, 7]        // бок 3
        ];
//        hull()
        polyhedron(points, faces);
        
        /*
        hull() {
            // Нижний срез профиля
            translate([0, 0, z1])
            rotate([0, 0, angle1]) {      // Поворачиваем вокруг ступицы на угол наклона
            translate([R_inner1, 0, 0])  // Перемещаем начало координат к ступице
//                rotate([90, 0, 0])  // Толщина идет по Z (вверх по трубе)
                straight_profile(
                    chord=chord1,
                    thickness=min(thickness_max, (H-z1)/20+0.4,z1/5+0.4),
                    height=0.00001
                );
            }
            
            // Верхний срез профиля
            translate([0, 0, z2])
            rotate([0, 0, angle2]) {      // Поворачиваем вокруг ступицы на угол наклона
            translate([R_inner2, 0, 0])  // Перемещаем начало координат к ступице
//                rotate([90, 0, 0])  // Толщина идет по Z (вверх по трубе)
                straight_profile(
                    chord=chord2,
                    thickness=min(thickness_max, (H-z2)/20+0.4,z2/5+0.4),
                    height=0.00001
                );
            }
        }
        */
    }
}

// Модуль конической ступицы
module hub_cone(
    D_bottom = D_hub_bottom,
    H = H_hub,
    $fn = 64
) {
    cylinder(h = H, r1 = D_bottom/2, r2 = 0, center = false);
}

// Модуль полной крыльчатки остановки вращения
module flow_straightener_assembly(
    D_tube = D_tube_inner,
    D_hub = D_hub_bottom,
    H_blade_height = H_blade,
    H_hub_height = H_hub,
    N = N_blades,
    thickness = thickness_max,
    angle_start_deg = angle_start,
    angle_end_deg = angle_end
) {
    // Центральная ступица
    difference() {
        union() {
            hub_cone(D_bottom = D_hub, H = H_hub_height);
                    // Лопасти (равномерно распределены по окружности)
            for (i = [0:N-1]) {
                rotate([0, 0, i * 360 / N])
                flow_straightener_blade(
                    R_outer = D_tube / 2,
                    R_inner_bottom = D_hub / 2,
                    H = H_blade_height,
                    angle_start = angle_start_deg,
                    angle_end = angle_end_deg,
                    thickness_max = thickness,
                    steps = 360
                );
            }
        };

        // Облегчение ступицы начинаем выше зоны подшипника,
        // чтобы под подшипник осталась "стаканная" посадка
        wall = 2.0;

        // где-то в difference() перед inner cone
        inner_start = bearing_w + bearing_shoulder;   // как раньше, например 8 мм

        top_cap = 2 * H_hub_height * wall / D_hub;
        D_bottom_inner = D_hub * (1 - inner_start / H_hub_height) - 2 * wall;
        H_inner = H_hub_height - inner_start - top_cap;

        translate([0,0,inner_start])
            hub_cone(D_bottom = D_bottom_inner, H = H_inner);

        // Карман под 608 снизу по центру
        translate([0,0,-0.05])
            cylinder(h = bearing_w + 0.1, d = bearing_od + bearing_fit, $fn = 96);

        // Сквозное отверстие под ось 8 мм
        translate([0,0,-0.05])
            cylinder(h = bearing_w * 2, d = bearing_id + 0.2, $fn = 64);
    

    

    }
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
groove_diameter = GROOVE_D_2,        // диаметр полукруглого желобка, мм
groove_depth = GROOVE_DEPTH_1_8      // глубина желобка (радиус), мм
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
            translate([groove_circle_radius - groove_depth, -groove_diameter/2, 0])
            square([groove_depth, groove_diameter], center = false);
        }

        

    }
    
    // Добавляем скругления на ушах (декоративное уточнение геометрии)
    // OpenSCAD имеет ограничения с филе, но можно использовать Minkowski
}


// Основной модуль для использования
module flow_straightener() {
    flow_straightener_assembly();
}

// Вызов для рендера (раскомментируйте для просмотра)
// flow_straightener();

// Тестовый рендер с видимой трубой для проверки
module test_with_tube() {
    tube_thickness = 3;
    D_tube_outer = D_tube_inner + 2 * tube_thickness;
    
    // Труба (для визуализации)

//    %translate([0, 0, -10])
    difference() {
        cylinder(h = 170, r = 92/2);
        translate([0,0,-0.5])
        cylinder(h = 171, r = 86/2);
    }
    
    // Крыльчатка
    flow_straightener();
    
    translate([0,0,170])
    rotate([180,0,45])
    adapter_plate();
    adapter_plate();
}

module just_tube() {
    difference() {
        cylinder(h = 80, r = 92/2);
        translate([0,0,-0.5])
        cylinder(h = 81, r = 86/2);
    }
    
    // Крыльчатка
//    flow_straightener();
    
    translate([0,0,80])
    rotate([180,0,45])
    adapter_plate();
    adapter_plate();
    
}

// Раскомментируйте для тестирования:
 test_with_tube();
//just_tube();
//adapter_plate();
