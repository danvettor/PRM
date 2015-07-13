classdef PRM_componente_e_obstaculo < PRM
    methods
        % constructor
        function prm = PRM_componente_e_obstaculo(varargin)
            prm = prm@PRM(varargin{:});
        end

    end % method

    methods (Access='protected')
    % private methods
        % create the roadmap
        function create_roadmap(prm)
            disp('Componente e Obstaculo')
            for j=1:prm.npoints
                % pick a point not in obstacle
                while true
                    x1 = prm.randi(numcols(prm.occgrid));
                    y1 = prm.randi(numrows(prm.occgrid));
                    if j < prm.npoints*0.0
                        x2 = x1+round((20*rand-1));
                        y2 = y1+round((20*rand-1));
                    else
                        x2 = x1+round(5*(2*rand-1));
                        y2 = y1+round(5*(2*rand-1));    
                    end
                    if x2<1 continue; end
                    if x2>100 continue; end
                    if y2<1 continue; end
                    if y2>100 continue; end    
                    if prm.occgrid(y1,x1) == 0 && prm.occgrid(y2,x2) == 1;
                        x=x1;
                        y=y1;
                        break;
                    end   
                    if prm.occgrid(y1,x1) == 1 && prm.occgrid(y2,x2) == 0;
                        x=x2;
                        y=y2;
                        break;
                    end                 
                end
                new = [x; y];

                vnew = prm.graph.add_node(new);

                [d,v] = prm.graph.distances(new);
                % test neighbours in order of increasing distance
                nc = prm.graph.nc;
                compo_aux=zeros(1,nc);
                %disp('Antes',prm.graph.component(1:length(d)))
                aux = prm.graph.component(1:length(d));
                for i=1:length(d)
                    if compo_aux(aux(v(i))) > 1
                        continue;
                    end    
                    if v(i) == vnew
                        continue;
                    end
                    if d(i) > prm.distthresh
                        continue;
                    end
                    if ~prm.testpath(new, prm.graph.coord(v(i)))
                        continue;
                    end
                    compo_aux(aux(v(i)))=compo_aux(aux(v(i)))+1;
                    prm.graph.add_edge(vnew, v(i));
                end
                %disp('Depois',prm.graph.component(1:i))
            end
            %prm.adicionaPontosUteis(100)
        end
    end % private methods

end % classdef
