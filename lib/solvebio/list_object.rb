module SolveBio
    class ListObject < SolveObject
        include Enumerable

        def all(params={})
            return request('get', self['url'], {:params => params})
        end

        def create(params={})
            return request('post', self['url'], {:params => params})
        end

        def next_page(params={})
            if self['links']['next']
                return request('get', self['links']['next'], {:params => params})
            end
            return nil
        end

        def prev_page(params={})
            if self['links']['prev']
                request('get', self['links']['prev'], {:params => params})
            end
            return nil
        end

        def at(i)
            self.to_a[i]
        end

        def to_a
            return Util.to_solve_object(self['data'])
        end

        def each(*pass)
            return self unless block_given?
            i = 0
            ary = self.dup
            done = false
            until done
                if i >= ary['data'].size
                    ary = next_page
                    break unless ary
                    i = 0
                end
                yield(ary.at(i))
                i += 1
            end
            return self
        end

        def first
            self['data'][0]
        end
    end
end
