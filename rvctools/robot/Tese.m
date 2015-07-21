%Parte inicial da toolbox
disp('Robotics, Vision & Control: (c) Peter Corke 1992-2011 http://www.petercorke.com')

if verLessThan('matlab', '7.0')
    warning('You are running a very old (and unsupported) version of MATLAB.  You will very likely encounter significant problems using the toolboxes but you are on your own with this');
end
tb = false;
rvcpath = fileparts( mfilename('fullpath') );

robotpath = fullfile(rvcpath, 'robot');
if exist(robotpath,'dir')
    addpath(robotpath);
    tb = true;
    startup_rtb
end

visionpath = fullfile(rvcpath, 'vision');
if exist(visionpath,'dir')
    addpath(visionpath);
    tb = true;
    startup_mvtb
end

if tb
    addpath(fullfile(rvcpath, 'common'));
    addpath(fullfile(rvcpath, 'simulink'));
end





%Parte inicial do PRM
clear tb rvcpath robotpath visionpath
prm=PRM;
load map1
goal = [20, 10];
start = [50, 30];
tam_x = 500;
tam_y = 300;
tam_x_obsta = 50;
tam_y_obsta = 30;
tam_raio_obsta = 30;
conta=zeros(1,6);





%Loop principal
tic
for i=1:1;
    map = zeros(tam_y, tam_x);
    
    
    
    %Obstáculos circulares
    for i = 1:20
        xR=prm.randi(tam_y-2*tam_raio_obsta) + tam_raio_obsta;
        yR=prm.randi(tam_x-2*tam_raio_obsta) + tam_raio_obsta;
        raio=tam_raio_obsta;
        %raio=prm.randi(tam_raio_obsta);
        for j = -raio:raio
            for k = -raio:raio
                if j*j + k*k < raio*raio
                    map(xR+j,yR+k) = 1;
                end
            end
        end
    end
    
    
    
    %Obstáculos retangulares
    for i = 1:20
        xR=prm.randi(tam_y-tam_y_obsta);
        yR=prm.randi(tam_x-tam_x_obsta);
        lR=tam_y_obsta;
        hR=tam_x_obsta;
        %lR=prm.randi(tam_y_obsta);
        %hR=prm.randi(tam_x_obsta);
        for j = xR:xR+lR
            for k = yR:yR+hR
                map(j,k) = 1;
            end
        end
    end
    prm=PRM(map);
    
    
    
    %Ponto inicial e final
    while true
        aa=prm.randi(tam_x);
        bb=prm.randi(tam_y);
        cc=prm.randi(tam_x);
        dd=prm.randi(tam_y);
        if prm.occgrid(bb,aa) == 0 && prm.occgrid(dd,cc) == 0 
          goal=[aa,bb];
          start=[cc,dd];  
          break
        end    
    end
    
    
    
    %Tesetes com os PRMs
    for j = 1:1
        switch (j)
            case 1
                prm=PRM_componente_e_celula(map);
            case 2
                prm=PRM_componente_e_obstaculo(map);
            case 3
                prm=PRM_celulas(map);
            case 4
                prm=PRM_old(map);
            case 5
                prm=PRM_obstaculo(map);
            case 6
                prm=PRM_componente(map);
        end
        prm.plan();
        prm.geraPontoGrafo(start);
        prm.geraPontoGrafo(goal);
        %prm.adicionaPontosUteis(100);
        prm.vgoal = prm.graph.closest(goal);      
        prm.vstart = prm.graph.closest(start);
        if prm.graph.component(prm.vstart) == prm.graph.component(prm.vgoal)
            conta(j)=conta(j)+1;
        end
    end
end




%Parte final do PRM
conta
toc




%Plotagem final
tic
prm.path(start, goal) 
toc


