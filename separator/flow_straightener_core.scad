// Общее ядро для стрейтенеров: базовые функции профиля и ступицы

use <common_params.scad>;

// Функция для генерации точек симметричного профиля NACA 00XX
// t - максимальная толщина в процентах от хорды (для NACA 0015: t=15)
// chord - длина хорды
// points - количество точек на половине профиля
function naca_symmetric_points(t, chord, points=20) = 
    let(
        // Генерируем точки от передней кромки (x=0) до задней (x=chord)
        x_coords = [for (i = [0:points-1]) i * chord / (points-1)],
        // Формула толщины для симметричного профиля NACA
        // y_t = 5*t*(0.2969*sqrt(x) - 0.1260*x - 0.3516*x^2 + 0.2843*x^3 - 0.1036*x^4)
        // где t - максимальная толщина в процентах от хорды
        thickness_factor = t / 100,
        y_coords = [
            for (x = x_coords)
                let(
                    x_norm = x / chord,  // Нормализованная координата (0..1)
                    y_t = x_norm > 0 ? 
                        5 * thickness_factor * chord * (
                            0.2969 * sqrt(x_norm) - 
                            0.1260 * x_norm - 
                            0.3516 * pow(x_norm, 2) + 
                            0.2843 * pow(x_norm, 3) - 
                            0.1036 * pow(x_norm, 4)
                        ) : 0
                )
                y_t
        ]
    )
    // Возвращаем точки: верхняя поверхность (от передней к задней), затем нижняя (от задней к передней)
    concat(
        [for (i = [0:points-1]) [x_coords[i], y_coords[i]]],
        [for (i = [points-1:-1:0]) [x_coords[i], -y_coords[i]]]
    );

// Функция ease-out для изменения угла
// t - параметр от 0 до 1
// Возвращает угол от angle_start до angle_end
function ease_out_angle(t, angle_start, angle_end) = 
    angle_start + (angle_end - angle_start) * (1 - pow(1 - t, 2));

// Точка профиля (x,y) в мировой СК: translate(R,0,0) -> rotate(c,s) -> translate(0,0,z)
function blade_point_world(p, R, c, s, z) = [
    (p[0] + R) * c - p[1] * s,
    (p[0] + R) * s + p[1] * c,
    z
];

// Модуль конической ступицы
module hub_cone(
    D_bottom = D_HUB_BOTTOM_30,
    H = H_HUB_110,
    $fn = 64
) {
    cylinder(h = H, r1 = D_bottom/2, r2 = 0, center = false);
}

