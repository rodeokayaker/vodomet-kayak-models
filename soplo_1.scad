// ============================================================================
// ПАРАМЕТРИЧЕСКИЙ СПЛИТТЕР И СОПЛО ДЛЯ ВОДОМЕТНОГО ДВИГАТЕЛЯ КАЯКА
// На основе технического задания TZ_Soplo.md
// ============================================================================

// Параметры визуализации
$fn = 100; // Качество окружностей (уменьшить до 50 для быстрого предпросмотра)

// ============================================================================
// ОСНОВНЫЕ ПАРАМЕТРЫ
// ============================================================================

// Входное сопло
inlet_diameter = 55;          // Диаметр входного сопла (мм)
wall_thickness = 4;           // Толщина стенок каналов (мм)

// Диффузор
diffuser_length = 125;        // Длина диффузора (мм)
diffuser_angle = 8;           // Угол расширения диффузора (градусы)
diffuser_outlet_diameter = 70; // Конечный диаметр диффузора (мм)

// Центральный разделитель
splitter_length = 350;        // Длина разделителя (мм)
splitter_start_thickness = 10; // Начальная толщина разделителя (мм)
splitter_end_thickness = 28;  // Конечная толщина разделителя (мм)

// Параллельные каналы
channel_width = 35;           // Ширина прямоугольного канала (мм)
channel_height = 25;          // Высота прямоугольного канала (мм)
channel_length = 175;         // Длина каналов (мм)
channel_bend_radius = 110;    // Радиус изгиба каналов (мм)
channel_outward_angle = 5;    // Угол изгиба наружу (градусы)
channel_downward_angle = 4;   // Угол изгиба вниз (градусы)

// Выходные сопла
outlet_nozzle_inlet_diameter = 35; // Входной диаметр выходного сопла (мм)
outlet_nozzle_outlet_diameter = 32; // Выходной диаметр сопла (мм)
outlet_nozzle_length = 100;   // Длина сужающейся части сопла (мм)
outlet_nozzle_angle = 11;     // Угол конвергента сопла (градусы)
nozzle_spacing = 200;         // Расстояние между выходными соплами (мм)

// ============================================================================
// ВСПОМОГАТЕЛЬНЫЕ МОДУЛИ
// ============================================================================

// Модуль: Диффузор (расширяющийся конус)
module diffuser() {
    cylinder(d1 = inlet_diameter, d2 = diffuser_outlet_diameter, h = diffuser_length);
}

// Модуль: Профиль центрального разделителя (NACA-подобная форма)
module splitter_profile(length, start_thickness, end_thickness) {
    hull() {
        // Начальная форма - закругленный нос
        translate([0, 0, 0])
            sphere(d = start_thickness);
        
        // Середина - линейное утолщение
        translate([length * 0.3, 0, 0])
            sphere(d = start_thickness + (end_thickness - start_thickness) * 0.3);
        
        translate([length * 0.6, 0, 0])
            sphere(d = start_thickness + (end_thickness - start_thickness) * 0.7);
        
        // Конец - максимальная толщина
        translate([length, 0, 0])
            sphere(d = end_thickness);
    }
}

// Модуль: Канал прямоугольного сечения
module rectangular_channel(width, height, length) {
    cube([length, width, height], center = false);
}

// Модуль: Конвергентное сопло (сужающийся конус)
module convergent_nozzle(inlet_d, outlet_d, length) {
    cylinder(d1 = inlet_d, d2 = outlet_d, h = length);
}

// Модуль: Переход от круглого сечения к прямоугольному
module circular_to_rectangular_transition(circle_d, rect_w, rect_h, trans_length) {
    hull() {
        // Круглое сечение в начале
        translate([0, 0, 0])
            rotate([0, 90, 0])
                cylinder(d = circle_d, h = 0.1);
        
        // Прямоугольное сечение в конце
        translate([trans_length, -rect_w/2, -rect_h/2])
            cube([0.1, rect_w, rect_h]);
    }
}

// Модуль: Изогнутый канал с прямоугольным сечением
module bent_channel(width, height, length, bend_radius, lateral_angle, vertical_angle) {
    // Упрощенная версия - используем линейное выдавливание с поворотом
    rotate([vertical_angle, 0, lateral_angle]) {
        translate([0, 0, 0])
            cube([length, width, height]);
    }
}

// ============================================================================
// ОСНОВНАЯ СБОРКА
// ============================================================================

module water_jet_splitter() {
    union() {
        // 1. Диффузор (вход)
        translate([0, 0, 0])
            difference() {
                diffuser();
                translate([0, 0, -1])
                    cylinder(d1 = inlet_diameter - 2*wall_thickness, 
                            d2 = diffuser_outlet_diameter - 2*wall_thickness, 
                            h = diffuser_length + 2);
            }
        
        // 2. Центральный разделитель
        translate([diffuser_length, 0, 0]) {
            rotate([0, 90, 0])
                splitter_profile(splitter_length, splitter_start_thickness, splitter_end_thickness);
        }
        
        // 3. Переходы от диффузора к прямоугольным каналам (левый и правый)
        transition_length = 50;
        transition_start_x = diffuser_length + splitter_length * 0.4;
        
        // Левый переход
        translate([transition_start_x, channel_width/2 + splitter_end_thickness/2, 0])
            rotate([0, 0, 0])
                circular_to_rectangular_transition(
                    diffuser_outlet_diameter/2 - wall_thickness, 
                    channel_width, 
                    channel_height, 
                    transition_length
                );
        
        // Правый переход
        translate([transition_start_x, -(channel_width/2 + splitter_end_thickness/2), 0])
            rotate([0, 0, 180])
                circular_to_rectangular_transition(
                    diffuser_outlet_diameter/2 - wall_thickness, 
                    channel_width, 
                    channel_height, 
                    transition_length
                );
        
        // 4. Внешние стенки каналов
        channel_start_x = transition_start_x + transition_length;
        
        // Левый канал - внешние стенки
        translate([channel_start_x, nozzle_spacing/4, -channel_height/2]) {
            difference() {
                bent_channel(channel_width + 2*wall_thickness, 
                            channel_height + 2*wall_thickness, 
                            channel_length, 
                            channel_bend_radius, 
                            channel_outward_angle, 
                            -channel_downward_angle);
                // Вычитаем внутренний канал
                translate([0, wall_thickness, wall_thickness])
                    bent_channel(channel_width, 
                                channel_height, 
                                channel_length + 10, 
                                channel_bend_radius, 
                                channel_outward_angle, 
                                -channel_downward_angle);
            }
        }
        
        // Правый канал - внешние стенки
        translate([channel_start_x, -nozzle_spacing/4, -channel_height/2]) {
            difference() {
                bent_channel(channel_width + 2*wall_thickness, 
                            channel_height + 2*wall_thickness, 
                            channel_length, 
                            channel_bend_radius, 
                            -channel_outward_angle, 
                            -channel_downward_angle);
                // Вычитаем внутренний канал
                translate([0, wall_thickness, wall_thickness])
                    bent_channel(channel_width, 
                                channel_height, 
                                channel_length + 10, 
                                channel_bend_radius, 
                                -channel_outward_angle, 
                                -channel_downward_angle);
            }
        }
        
        // 5. Выходные сопла
        nozzle_start_x = channel_start_x + channel_length;
        
        // Левое сопло
        translate([nozzle_start_x, nozzle_spacing/2, -channel_height/2]) {
            rotate([channel_downward_angle, 0, channel_outward_angle])
                rotate([0, 90, 0])
                    difference() {
                        convergent_nozzle(outlet_nozzle_inlet_diameter + 2*wall_thickness, 
                                         outlet_nozzle_outlet_diameter + 2*wall_thickness, 
                                         outlet_nozzle_length);
                        translate([0, 0, -1])
                            convergent_nozzle(outlet_nozzle_inlet_diameter, 
                                             outlet_nozzle_outlet_diameter, 
                                             outlet_nozzle_length + 2);
                    }
        }
        
        // Правое сопло
        translate([nozzle_start_x, -nozzle_spacing/2, -channel_height/2]) {
            rotate([channel_downward_angle, 0, -channel_outward_angle])
                rotate([0, 90, 0])
                    difference() {
                        convergent_nozzle(outlet_nozzle_inlet_diameter + 2*wall_thickness, 
                                         outlet_nozzle_outlet_diameter + 2*wall_thickness, 
                                         outlet_nozzle_length);
                        translate([0, 0, -1])
                            convergent_nozzle(outlet_nozzle_inlet_diameter, 
                                             outlet_nozzle_outlet_diameter, 
                                             outlet_nozzle_length + 2);
                    }
        }
    }
}

// ============================================================================
// ВИЗУАЛИЗАЦИЯ И РЕНДЕРИНГ
// ============================================================================

// Основная модель
water_jet_splitter();

// Опциональный разрез для визуализации внутренней геометрии
// Раскомментируйте следующий блок для просмотра разреза:
/*
difference() {
    water_jet_splitter();
    translate([-10, -500, -500])
        cube([1000, 1000, 500]);
}
*/

// ============================================================================
// ИНСТРУКЦИИ ПО ИСПОЛЬЗОВАНИЮ
// ============================================================================
// 1. Откройте этот файл в OpenSCAD
// 2. Нажмите F5 для предпросмотра (или F6 для полного рендеринга)
// 3. Настройте параметры в разделе "ОСНОВНЫЕ ПАРАМЕТРЫ" по необходимости
// 4. Экспортируйте в STL: File → Export → Export as STL
// 5. Для улучшенного качества печати увеличьте $fn до 150-200

// РЕКОМЕНДАЦИИ ПО 3D-ПЕЧАТИ:
// - Материал: PETG или ABS
// - Ориентация: расположите модель горизонтально (входное сопло направлено вперед)
// - Слой: 0.2 мм
// - Заполнение: 30-50% (гироидное или треугольное)
// - Поддержки: минимальные (возможно потребуются для выходных сопел)
// - Постобработка: шлифовка внутренних поверхностей для снижения шероховатости
