%PRM Probabilistic RoadMap navigation class
%
% A concrete subclass of the abstract Navigation class that implements the
% probabilistic roadmap navigation algorithm over an occupancy grid.  This
% performs goal independent planning of roadmaps, and at the query stage
% finds paths between specific start and goal points.
%
% Methods::
%
% plan         Compute the roadmap
% path         Compute a path to the goal
% visualize    Display the obstacle map (deprecated)
% plot         Display the obstacle map
% display      Display the parameters in human readable form
% char         Convert to string
%
% Example::
%
%        load map1              % load map
%        goal = [50,30];        % goal point
%        start = [20, 10];      % start point
%        prm = PRM(map);        % create navigation object
%        prm.plan()             % create roadmaps
%        prm.path(start, goal)  % animate path from this start location
%
% References::
%
% - Probabilistic roadmaps for path planning in high dimensional configuration spaces,
%   L. Kavraki, P. Svestka, J. Latombe, and M. Overmars, 
%   IEEE Transactions on Robotics and Automation, vol. 12, pp. 566-580, Aug 1996.
% - Robotics, Vision & Control, Section 5.2.4,
%   P. Corke, Springer 2011.
%
% See also Navigation, DXform, Dstar, PGraph.


% Copyright (C) 1993-2015, by Peter I. Corke
%
% This file is part of The Robotics Toolbox for MATLAB (RTB).
% 
% RTB is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% RTB is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
% 
% You should have received a copy of the GNU Leser General Public License
% along with RTB.  If not, see <http://www.gnu.org/licenses/>.
%
% http://www.petercorke.com


% Peter Corke 8/2009.
% Teste pra commitar

classdef PRM < Navigation

    properties
        npoints         % number of sample points
        distthresh      % distance threshold, links between vertices
                        % must be less than this.

        graph           % graph Object representing random nodes

        vgoal           % index of vertex closest to goal
        vstart          % index of vertex closest to start
        localGoal       % next vertex on the roadmap
        localPath       % set of points along path to next vertex
        gpath           % list of vertices between start and goal
    end

    methods

        function geraPontoGrafo(prm, new)
            vnew = prm.graph.add_node(new);
            contador = 0;

            [d,v] = prm.graph.distances(new);
            % test neighbours in order of increasing distance
            for i=1:length(d)
                if contador >= 5
                    break
                end
                %length(d)
                i;
                if v(i) == vnew
                    continue;
                end
                if d(i) > prm.distthresh
                    continue;
                end
                if ~prm.testpath(new, prm.graph.coord(v(i)))
                    continue;
                end
                prm.graph.add_edge(vnew, v(i));
                contador = contador + 1;
            end
        end

        % constructor
        function prm = PRM(varargin)
            %PRM.PRM Create a PRM navigation object
            %
            % P = PRM(MAP, options) is a probabilistic roadmap navigation
            % object, and MAP is an occupancy grid, a representation of a
            % planar world as a matrix whose elements are 0 (free space) or 1
            % (occupied).
            %
            % Options::
            %  'npoints',N      Number of sample points (default 100)
            %  'distthresh',D   Distance threshold, edges only connect vertices closer 
            %                   than D (default 0.3 max(size(occgrid)))
            %
            % Other options are supported by the Navigation superclass.
            %
            % See also Navigation.Navigation.


            % invoke the superclass constructor, it handles some options
            prm = prm@Navigation(varargin{:});

            % create an empty 2D graph
            prm.graph = PGraph(2);

            % parse out PRM specific options and save in the navigation object
            opt.npoints = 100;
            opt.distthresh = 0.3*max(size(prm.occgrid));
            [opt,args] = tb_optparse(opt, varargin);
            prm.npoints = opt.npoints;
            prm.distthresh = opt.distthresh;
        end

        function plan(prm)
        %PRM.plan Create a probabilistic croadmap
        %
        % P.plan() creates the probabilistic roadmap by randomly
        % sampling the free space in the map and building a graph with
        % edges connecting close points.  The resulting graph is kept
        % within the object.

        % build a graph over the free space
            prm.message('create the graph');

            prm.graph.clear();  % empty the graph
            create_roadmap(prm);  % build the graph
        end
        
        function p = path(prm, start, goal)
        %PRM.path Find a path between two points
        %
        % P.path(START, GOAL) finds and displays a path from START to GOAL
        % which is overlaid on the occupancy grid.
        %
        % X = P.path(START) returns the path (2xM) from START to GOAL.
        
            if nargin < 3
                error('must specify start and goal');
            end
            
            % set the goal coordinate
            %geraPontoGrafo(start);
            %geraPontoGrafo(goal);
            prm.goal = goal;

            % invoke the superclass path function, which iterates on our
            % next method
            if nargout == 0
                path@Navigation(prm, start);
            else
                p = path@Navigation(prm, start);
            end
        end

        % Handler invoked by Navigation.path() to start the navigation process
        %
        %   - find a path through the graph
        %   - determine vertices closest to start and goal
        %   - find path to first vertex
        function navigate_init(prm, start)

            % find the vertex closest to the goal
            prm.vgoal = prm.graph.closest(prm.goal);
            
            % find the vertex closest to the start
            prm.vstart = prm.graph.closest(start);
            
                      

            % are the vertices connected?
            if prm.graph.component(prm.vstart) ~= prm.graph.component(prm.vgoal)
                error('PRM:plan:nopath', 'PRM: start and goal not connected: rerun the planner');
            end
            
            % find a path through the graph
            prm.message('planning path through graph');
            prm.graph.goal(prm.vgoal);   % set the goal 
            prm.gpath = prm.graph.path(prm.vstart);

            % the path is a list of nodes from vstart to vgoal
            % discard the first vertex, since we plan a local path to it
            prm.gpath = prm.gpath(2:end);

            % start the navigation engine with a path to the nearest vertex
            prm.graph.highlight_node(prm.vstart);

            prm.localPath = bresenham(start, prm.graph.coord(prm.vstart));
            prm.localPath = prm.localPath(2:end,:);
        end

        % Invoked for each step on the path by path() method.
        function n = next(prm, p)

            if all(p(:) == prm.goal)
                n = [];     % signal that we've arrived
                return;
            end

            % we take the next point from the localPath
            if numrows(prm.localPath) == 0
                % local path is consumed, move to next vertex
                if isempty(prm.gpath)
                    % we have arrived at the goal vertex
                    % make the path from this vertex to the goal coordinate
                    prm.localPath = bresenham(p, prm.goal);
                    prm.localPath = prm.localPath(2:end,:);
                    prm.localGoal = [];
                else
                    % set local goal to next vertex in gpath and remove it from the list
                    prm.localGoal = prm.gpath(1);
                    prm.gpath = prm.gpath(2:end);

                    % compute local path to the next vertex
                    prm.localPath = bresenham(p, prm.graph.coord(prm.localGoal));
                    prm.localPath = prm.localPath(2:end,:);
                    prm.graph.highlight_node(prm.localGoal);
                end
            end

            n = prm.localPath(1,:)';     % take the first point
            prm.localPath = prm.localPath(2:end,:); % and remove from the path
        end

        function s = char(prm)
        %PRM.char  Convert to string
        %
        % P.char() is a string representing the state of the PRM
        % object in human-readable form.
        %
        % See also PRM.display.


            % invoke the superclass char() method
            s = char@Navigation(prm);

            % add PRM specific stuff information
            s = char(s, sprintf('  graph size: %d', prm.npoints));
            s = char(s, sprintf('  dist thresh: %f', prm.distthresh));
            s = char(s, char(prm.graph) );
        end
        
        
        function plot(prm, varargin)
        %PRM.plot Visualize navigation environment
        %
        % P.plot() displays the occupancy grid with an optional distance field.
        %
        % Options::
        %  'goal'            Superimpose the goal position if set
        %  'nooverlay'       Don't overlay the PRM graph
            
            opt.nooverlay = false;
            [opt,args] = tb_optparse(opt, varargin);
            
            % display the occgrid
            plot@Navigation(prm, args{:});
            
            if ~opt.nooverlay
                hold on
                prm.graph.plot()%varargin{:});
                hold off
            end
        end
        
        function vf=gerapontos(prm,inicio,final,quantidade)
            if quantidade == 0
                vf=[];
                return 
            end    
            conta_obst=0;
            x=floor(inicio(1)+rand*(final(1)-inicio(1)));
            y=floor(inicio(2)+rand*(final(2)-inicio(2)));
            while true;  
            xaux=round(2*rand-1);
            yaux=round(2*rand-1);
              if xaux~=0 || yaux~=0 break;
              end
            end
            while true
                %x = prm.randi(numcols(prm.occgrid));
                %y = prm.randi(numrows(prm.occgrid));
                if x < 1 || x > 100 || y < 1 || y > 100 
                    x=floor(inicio(1)+rand*(final(1)-inicio(1)));
                    y=floor(inicio(2)+rand*(final(2)-inicio(2)));
                end
                if prm.occgrid(y,x) == 0
                    break;
                else
                    x=x+xaux;
                    y=y+yaux;
                end    
            end
            p = [x; y];
            quantidade=quantidade-1;
            medio=(inicio+final)/2;
            vp1=prm.gerapontos(inicio,medio,floor(quantidade/4));
            quantidade=quantidade-floor(quantidade/4);
            paux1=[inicio(1),medio(2)];
            paux2=[medio(1),final(2)];
            vp2=prm.gerapontos(paux1,paux2,floor(quantidade/3));
            quantidade=quantidade-floor(quantidade/3);
            paux3=[medio(1),inicio(2)];
            paux4=[final(1),medio(2)];
            vp3=prm.gerapontos(paux3,paux4,floor(quantidade/2));
            quantidade=quantidade-floor(quantidade/2);
            vp4=prm.gerapontos(medio,final,quantidade);
            vf=[p,vp1,vp2,vp3,vp4];
        end

        function adicionaPontosUteis(prm, n)
            cont = 0;
            %disp('aaa')
            while prm.graph.nc>1 && cont < n
                cont = cont + 1;
                %n
                % pick a point not in obstacle
                while true
                    x = prm.randi(numcols(prm.occgrid));
                    y = prm.randi(numrows(prm.occgrid));
                    if prm.occgrid(y,x) == 0
                        break;
                    end
                end
                new = [x; y];
                
                %vnew = prm.graph.add_node(new);

                %[d,v] = prm.graph.distances(new);
                % test neighbours in order of increasing distance
                nc = prm.graph.nc;
                compo_aux=zeros(1,nc);
                %disp('Antes',prm.graph.component(1:length(d)))
                a_adicionar = [];
                aux = prm.graph.component(1:prm.graph.n);
                for i=1:length(aux)
                    if compo_aux(aux(i)) > 0
                        continue;
                    end
                    if ~prm.testpath(new, prm.graph.coord(i))
                        continue;
                    end
                    compo_aux(aux(i))=compo_aux(aux(i))+1;
                    a_adicionar = [a_adicionar i];
                    %prm.graph.add_edge(vnew, v(i));
                end
                if(sum(compo_aux) ~= 1) 
                    vnew = prm.graph.add_node(new);
                    new
                    for j = 1:length(a_adicionar)
                        prm.graph.add_edge(vnew, a_adicionar(j));
                    end
                end
                %disp('Depois',prm.graph.component(1:i))
            end    
        end
    end % method

    methods (Access='protected')
    % private methods
        % create the roadmap
        
        function create_roadmap(prm)
            inicio = [1,1];
            fim = [100,100];
            ponto_celula=prm.gerapontos(inicio, fim, prm.npoints);
            %ponto_celula_aux=prm.gerapontos(inicio, fim, prm.npoints);
            %goal=[50,30];
            %start=[20,10];
            %ponto_celula =[ponto_celula_aux, start', goal'];
            
            for j=1:length(ponto_celula);
                % pick a point not in obstacle
                %while true
                %    x = prm.randi(numcols(prm.occgrid));
                %    y = prm.randi(numrows(prm.occgrid));
                %    if prm.occgrid(y,x) == 0
                %        break;
                %    end
                %end
                %new = [x; y];
                j;
                new = ponto_celula(2*j-1:2*j);
                prm.geraPontoGrafo(new);
                
            end
        end

        % test the path from p1 to p2 is entirely in free space
        function c = testpath(prm, p1, p2)
            p = bresenham(p1, p2);

            for pp=p'
                if prm.occgrid(pp(2), pp(1)) > 0
                    c = false;
                    return;
                end
            end
            c = true;
        end
        
        


    end % private methods

end % classdef
