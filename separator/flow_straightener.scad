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

// Общие параметры
use <common_params.scad>;
use <flow_straightener_core.scad>;

// Параметры
D_tube_inner = D_TUBE_IN_86;        // Внутренний диаметр трубы, мм
D_hub_bottom = D_HUB_BOTTOM_30;     // Диаметр ступицы внизу, мм
H_blade = H_BLADE_100;              // Высота крыльчатки (лопастей), мм
H_hub = H_HUB_110;                  // Высота ступицы, мм
N_blades = 7;                       // Количество лопастей
thickness_max = TH_BLADE_1_5;       // Толщина прямого профиля, мм
angle_start = ANGLE_BLADE_START_NEG_45; // Начальный угол лопастей, градусы (отрицательный для противоположного вращения)
angle_end = ANGLE_BLADE_END_0;      // Конечный угол лопастей, градусы

// Радиусы
R_outer = D_tube_inner / 2;      // Внешний радиус (к стенке трубы)
R_inner_bottom = D_hub_bottom / 2; // Внутренний радиус внизу (к ступице)

// Модуль для создания прямого профиля (прямоугольного)
// chord - длина хорды (радиально от ступицы к стенке)
// thickness - толщина профиля (тангенциально, вокруг окружности)
// height - высота профиля (вдоль оси трубы)
module straight_profile(chord=50, thickness=1.5, height=1) {
    translate([0, -thickness/2, 0])
    cube([chord, thickness, height]);
}

// Модуль одной лопасти
module flow_straightener_blade(
    R_outer = R_outer,
    R_inner_bottom = R_inner_bottom,
    H = H_blade,
    angle_start = angle_start,
    angle_end = angle_end,
    thickness_max = thickness_max,
    steps = 60
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
        H_bend = H / 2;  // Высота зоны изгиба (первая половина)
        
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
        R_inner1 = max(0, R_inner_bottom * (1 - z1 / H_hub));
        R_inner2 = max(0, R_inner_bottom * (1 - z2 / H_hub));
        
        // Длина хорды на данном уровне
        // Лопасть идет от ступицы к стенке под углом angle от радиального направления
        // Реальная длина хорды больше, чем радиальное расстояние из-за наклона
        // Но для упрощения используем радиальное расстояние как приближение
        // (точный расчет требует учета угла наклона)
        chord1 = R_outer - R_inner1;
        chord2 = R_outer - R_inner2;
        
        // Для прямого профиля толщина постоянная (1.5 мм), не зависит от хорды
        
        // Толщина профиля на уровнях z1 и z2 (как в straight_profile)
        th1 = min(thickness_max, (H - z1) / 20 + 0.4, z1 / 5 + 0.4);
        th2 = min(thickness_max, (H - z2) / 20 + 0.4, z2 / 5 + 0.4);
        a1 = angle1 * 0.01745329252;
        a2 = angle2 * 0.01745329252;
        // 4 угла профиля в локальных координатах (straight_profile: хорда X, толщина Y)
        lo1 = [[0, -th1/2], [chord1, -th1/2], [chord1, th1/2], [0, th1/2]];
        lo2 = [[0, -th2/2], [chord2, -th2/2], [chord2, th2/2], [0, th2/2]];
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
        polyhedron(points, faces);
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
            steps = 60
        );
    }
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
    %translate([0, 0, -10])
    difference() {
        cylinder(h = H_blade + 20, r = D_tube_outer/2, $fn=64);
        cylinder(h = H_blade + 21, r = D_tube_inner/2, $fn=64);
    }
    
    // Крыльчатка
    flow_straightener();
}

// Раскомментируйте для тестирования:
// test_with_tube();

// --- 3D «восьмиугольник»: два прямоугольника сверху и снизу, повёрнутые друг относительно друга ---
// Тело строится через polyhedron(): 8 вершин (4 снизу, 4 сверху) и грани между ними.

module rotated_rect_prism(width, depth, height, twist_deg = 45, center = false) {
    w = width / 2;
    d = depth / 2;
    z0 = center ? -height/2 : 0;
    z1 = z0 + height;
    rad = twist_deg * 0.01745329252;  // градусы -> радианы
    c = cos(rad);
    s = sin(rad);
    // Углы нижнего прямоугольника (индексы 0..3)
    bottom = [[-w,-d], [w,-d], [w,d], [-w,d]];
    // Верхний прямоугольник — те же углы, повёрнуты вокруг Z
    top = [ for (p = bottom) [ p[0]*c - p[1]*s, p[0]*s + p[1]*c ] ];
    points = [
        [bottom[0][0], bottom[0][1], z0], [bottom[1][0], bottom[1][1], z0],
        [bottom[2][0], bottom[2][1], z0], [bottom[3][0], bottom[3][1], z0],
        [top[0][0], top[0][1], z1],       [top[1][0], top[1][1], z1],
        [top[2][0], top[2][1], z1],       [top[3][0], top[3][1], z1]
    ];
    // Грани: низ [0,3,2,1], верх [4,5,6,7], 4 боковые (нормаль наружу — обход по ЧС по виду снаружи)
    faces = [
        [0, 3, 2, 1],   // низ
        [4, 5, 6, 7],   // верх
        [0, 1, 5, 4],   [1, 2, 6, 5],   [2, 3, 7, 6],   [3, 0, 4, 7]
    ];
    polyhedron(points, faces);
}

// Пример: прямоугольник 40x20 мм, высота 30 мм, верх повёрнут на 45°
// rotated_rect_prism(40, 20, 30, twist_deg = 45);
