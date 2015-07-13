classdef PRM_celulas < PRM
    methods
        % constructor
        function prm = PRM_celulas(varargin)
            prm = prm@PRM(varargin{:});
        end

    end % method

    methods (Access='protected')
    % private methods
        % create the roadmap
        function create_roadmap(prm)
            disp('Celulas')
            inicio = [1,1];
            fim = [100,100];
            ponto_celula=prm.gerapontos(inicio, fim, prm.npoints);
            
            for j=1:prm.npoints
                new=ponto_celula(2*j-1:2*j);
                
                vnew = prm.graph.add_node(new);

                [d,v] = prm.graph.distances(new);
                % test neighbours in order of increasing distance
                for i=1:length(d)
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
                end
            end
        end
    end % private methods

end % classdef
