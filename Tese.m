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

clear tb rvcpath robotpath visionpath

load map1
goal = [20, 10];
start = [50, 30];

conta=zeros(1,6);

tic
for i=1:2;
    map = zeros(100, 100);
    for i = 1:50
        xR=prm.randi(90);
        yR=prm.randi(90);
        lR=prm.randi(10);
        hR=prm.randi(10);
        for j = xR:xR+lR
            for k = yR:yR+hR
                map(j,k) = 1;
            end
        end
    end
    prm=PRM(map);
    while true
        aa=prm.randi(100);
        bb=prm.randi(100);
        cc=prm.randi(100);
        dd=prm.randi(100);
        if prm.occgrid(bb,aa) == 0 && prm.occgrid(dd,cc) == 0 
          goal=[aa,bb];
          start=[cc,dd];  
          break
        end    
    end
    for j = 1:6
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
conta
toc
%disp('Teste')
tic
prm.path(start, goal) 
toc


