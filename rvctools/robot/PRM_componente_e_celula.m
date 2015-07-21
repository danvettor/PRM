classdef PRM_componente_e_celula < PRM
    methods
        % constructor
        function prm = PRM_componente_e_celula(varargin)
            prm = prm@PRM(varargin{:});
        end

    end % method

    methods (Access='protected')
    % private methods
        % create the roadmap
        function create_roadmap(prm)
            disp('Componente e Celula')
            inicio = [1,1];
            fim = [100,100];
            ponto_celula=prm.gerapontos(inicio, fim, prm.npoints);
            
            for j=1:prm.npoints
                new=ponto_celula(2*j-1:2*j);
                
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
        end
    end % private methods

end % classdef
