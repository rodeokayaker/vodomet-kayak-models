// Параметрическая модель ВНУТРЕННЕГО КАНАЛА Y‑разделителя для CFD (SimFlow)

use <common_params.scad>;

$fn=96;

module transition(
    Din,
    Dout,
    angle, 
    roundrad = 10
)
{
    hull(){
//        sphere(r = max(Din/2, Dout/2));
        translate([0,0,-Din/2])
            cylinder(h=Din/2, r=Din/2, center=false);
        
        rotate([0,angle,0])
            cylinder(h=Dout,r=Dout/2, center= false);
        rotate([0,-angle,0])
            cylinder(h=Dout,r=Dout/2, center= false);
            
        
    }
    

    
    major_radius = Dout/2 + roundrad;
    minor_radius = Dout/2;
    sector_angle = 180 - 2*angle;

    translate([0,0,(roundrad+Dout/2)/sin(angle)])
    rotate([-90,0,0])
    rotate([0,0,angle])
        rotate_extrude(angle = sector_angle, convexity = 10)
          translate([major_radius, 0, 0])
            circle(r = minor_radius);   
    
    
    
}

module transition_improved(Din, Dout, angle, roundrad=10) {
    // Плавный S-образный переход вместо hull()
    steps = 96;
    transition_length = (roundrad+Dout/2)/sin(angle)-roundrad-Dout/2;
    shift=transition_length * tan(angle);
    
    for (i = [0:steps-1]) {
        t = i / steps;
        t_next = (i + 1) / steps;
        
        // Сглаженная интерполяция (ease-in-out)
        blend = (1 - cos(t * 180)) / 2;
        blend_next = (1 - cos(t_next * 180)) / 2;
        
        ub = (1 - cos(t*90));
        ub_next= (1 - cos(t_next*90));
        
        lb = sin(t*90);
        lb_next = sin(t_next*90);
        
        r1 = Din/2 * (1 - blend) + Dout/2 * blend;
        r2 = Din/2 * (1 - blend_next) + Dout/2 * blend_next;
        
        r1_2 = Din/2 * (1 - ub) + Dout/2 * ub;
        r2_2 = Din/2 * (1 - ub_next) + Dout/2 * ub_next;
        
        // Постепенное расширение в плоскости XZ
        w1 = blend * Dout * sin(angle);
        w2 = blend_next * Dout * sin(angle);
        
        s1 = ub * shift;
        s2 = ub_next * shift;
        scl = 1/cos(angle);
        
        hull() {
            translate([s1, 0, t * transition_length])
                scale([/*1 + w1/Din*/(1+lb*(scl-1))*(r1_2/r1), 1, 1])
                cylinder(h = 0.1, r = r1);
            translate([s2, 0, t_next * transition_length])
                scale([/*1 + w2/Din*/(1+lb_next*(scl-1))*(r2_2/r2), 1, 1])
                cylinder(h = 0.1, r = r2);
            translate([-s1, 0, t * transition_length])
                scale([/*1 + w1/Din*/(1+lb*(scl-1))*(r1_2/r1), 1, 1])
                cylinder(h = 0.1, r = r1);
            translate([-s2, 0, t_next * transition_length])
                scale([/*1 + w2/Din*/(1+lb_next*(scl-1))*(r2_2/r2), 1, 1])
                cylinder(h = 0.1, r = r2);

        }
        
        
    }
    
    major_radius = Dout/2 + roundrad;
    minor_radius = Dout/2;
    sector_angle = 180 - 2*angle;

    translate([0,0,(roundrad+Dout/2)/sin(angle)])
    rotate([-90,0,0])
    rotate([0,0,angle])
        rotate_extrude(angle = sector_angle, convexity = 10)
          translate([major_radius, 0, 0])
            circle(r = minor_radius); 
    
    rotate([90,0,0])
    translate([0,0,-Dout/2])
    linear_extrude(height = Dout){
        difference(){    
            polygon([
            [0,0],
            [major_radius*cos(angle),major_radius/sin(angle)-major_radius*sin(angle)],
            [-major_radius*cos(angle),major_radius/sin(angle)-major_radius*sin(angle)]
            ]);
            translate([0,major_radius/sin(angle),0]) circle(r = major_radius);
        }
    };
}

module transition_box(Din, Dout, angle, roundrad=10){
    
    height = (roundrad+Dout/2)/sin(angle)-roundrad-Dout/2;
    width = max((Dout+roundrad)*cos(angle),Din/2);
    wy = max(Dout/2,Din/2);
    
    linear_extrude(height)
    polygon([
    [width,wy], [width, - wy], [-width, -wy], [-width, wy]    
    ]);
    
}



module y_separator_channel(
    Din = D_TUBE_IN_86,      // диаметр входа, мм
    Dout = D_BRANCH_OUT_61,  // диаметр выхода (каждой ветви), мм
    L_in = 0,               // длина прямого входного участка, мм
    L_branch = L_BRANCH_292, // длина наклонного участка ветви до выхода на горизонталь, мм
    L_core = L_CORE_150,    // длина/масштаб зоны развилки, мм
    L_out = L_OUT_40,       // длина горизонтального прямого участка у выхода, мм
    L_exit = L_EXIT_20,
    L_exittrans = L_EXIT_TRANS_50,
    Dexit = D_EXIT_44,
    branch_angle = ANGLE_BRANCH_20,  // угол отклонения ветви от оси входа, градусы
    R_round = 0,        // радиус скругления углов, мм
    $fn = 96            // детализация окружностей

) {
    Rin  = Din  / 2;
    Rout = Dout / 2;
    // Базовые радиусы до скругления (уменьшаем на R_round, чтобы
    // после Minkowski с шаром фактический радиус был близок к Rin/Rout)
    r_in_base  = max(Rin  - R_round, 0.1);
    r_out_base = max(Rout - R_round, 0.1);    
    
    round_radius = 100;

    union() {
        // Входной участок + часть ядра Y вдоль оси Z
        // Ось входа совпадает с осью Z, поток идёт от -Z к +Z
        translate([0, 0, -L_in])
            cylinder(h = L_in , r = r_in_base, center = false);

        // Центральное утолщение / сглаживание развилки
        // Даёт более плавный переход между входом и ветвями
//        sphere(r = max(Rin, Rout));
//        transition(Din=Din, Dout=Dout, angle=branch_angle);
        transition_improved(Din=Din, Dout=Dout, angle=branch_angle);
        
        

        // Две выходные ветви, симметрично относительно оси Z
        // Плоскость Y–Z, ветви отклонены по оси Y
        for (a = [-branch_angle, branch_angle]) {
//            hull(){
            difference(){
            rotate([0, a, 0])   // поворот вокруг оси X: разъезд по Y–Z
                translate([0, 0, 0])  // начало в центре (общая точка с входом)
                    cylinder(h = L_branch-(Dout/2+round_radius)*sin(branch_angle/2)-0, r = r_out_base, center = false);
                transition_box(Din=Din, Dout=Dout, angle=branch_angle);
            }
/*            translate([
                L_branch * sin(a),
                0,
                L_branch * cos(a)])
                sphere( r = r_out_base );*/
          rotate([0,0,90*(a/branch_angle-1)])
          translate([L_branch * sin(branch_angle)-Dout/2-round_radius,0,L_branch * cos(branch_angle)+(Dout/2+round_radius)*sin(branch_angle/2)])
          rotate([-90,0,0])
          rotate_extrude(angle = branch_angle, convexity = 10)
           translate([Dout/2+round_radius, 0, 0])
             circle(r = Dout/2);   
            
            
        
            translate([
                L_branch * sin(a),
                0,
                L_branch * cos(a)+(Dout/2+round_radius)*sin(branch_angle/2)
            ])
                cylinder(h = L_out-(Dout/2+round_radius)*sin(branch_angle/2), r = r_out_base, center = false);
                
//            }
            translate([L_branch * sin(a), 0, L_branch * cos(a)+L_out])
            cylinder(h=L_exittrans,r1=Dout/2,r2=Dexit /2,center=false);
            translate([L_branch * sin(a), 0, L_branch * cos(a)+L_out+L_exittrans])
            cylinder(h=L_exit,r=Dexit/2,center=false);
            
            
        }
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
groove_depth = GROOVE_DEPTH_1        // глубина желобка (радиус), мм
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

module separator_wing(

height = 170,
Dout = 61,
angle = 20,
width = 100,
wb = 2,
w = 20
)
{
    
/*    
    steps = 96;
    
    
    //polygon([[-w/2,-width/2],[-w/2,width/2],[w/2,width/2],[w/2,-width/2]]);
    scale = 10;
    
    shift=height * tan(angle);
    
    
    //cylinder(h=height/steps,r=(1-(1/steps))*(1-(1/steps))/(1/steps),center = false);
    
    for (i = [1:steps-1]) {
        t = i / steps;
        t_next = (i + 1) / steps;
        
        r1 = (((1-t)/(t)) + 1) *Dout;
        r2 = (((1-(t_next))/(t_next)) + 1)  *Dout;
        
        blend = (1 - cos(t * 180)) / 2;
        blend_next = (1 - cos(t_next * 180)) / 2;
        
        a = blend * angle;
        translate([0,0,t*height])
//        rotate([0,a,0])
        hull()
        {
            translate([r2,0,height/steps])
            circle(r2);
            translate([r1,0,0])
            circle(r1);
        }
        
        
        
        
        
        
    }

*/    
    
    rotate([90, 0, 0])
    translate([0,0,-width/2])
    linear_extrude(width)
    polygon([
        [wb/2,0],
        [w/2,height],
        [-w/2,height],
        [-wb/2,0]
    ]);
}

module separator_all(){



// Вызов модуля для рендера/экспорта
difference(){
y_separator_channel(
    Din = D_TUBE_OUT_92,           // диаметр входа, мм
    Dout = D_BRANCH_OUT_67,        // диаметр выхода (каждой ветви), мм
    L_branch = L_BRANCH_292,       // длина наклонного участка ветви до выхода на горизонталь, мм
    L_core = L_CORE_150,           // длина/масштаб зоны развилки, мм
    branch_angle = ANGLE_BRANCH_20,// угол отклонения ветви от оси входа, градусы
    R_round = 0,                   // радиус скругления углов, мм
    Dexit = D_EXIT_50,
    $fn = 96                        // детализация окружностей
    );

  y_separator_channel($fn=96);
//translate([0,0,-50])
//separator_wing();
}

adapter_plate();
//rotate([0,180,0])
//adapter_plate();

//translate([0,0,-150])
//adapter_plate();



rotate([0,20,0])
translate([0,0,200])
{
/*adapter_plate(outer_diameter = 90,      
inner_diameter = 61,  
groove_circle_radius = 38,
bolt_distance_from_center = 45
);*/
    
rotate([0,180,0])    
adapter_plate(outer_diameter = ADAPTER_OUTER_D_90,
inner_diameter = ADAPTER_INNER_D_61,
groove_circle_radius = GROOVE_R_38,
bolt_distance_from_center = EAR_BOLT_R_45
);    
}

rotate([0,-20,0])
translate([0,0,200])
{
/*adapter_plate(outer_diameter = 90,      
inner_diameter = 61,  
groove_circle_radius = 38,
bolt_distance_from_center = 45
);*/
    
rotate([0,180,0])    
adapter_plate(outer_diameter = ADAPTER_OUTER_D_90,
inner_diameter = ADAPTER_INNER_D_61,
groove_circle_radius = GROOVE_R_38,
bolt_distance_from_center = EAR_BOLT_R_45
); 
}
}

difference(){
    separator_all();
    {
        rotate([0,-20,0])
        translate([-100,-100,200])
        cube([200,200,400]);    
        rotate([0,20,0])
        translate([-100,-100,200])
        cube([200,200,400]);   
        translate([-100,-100,-400])
        cube([200,200,400]);     
    }
}