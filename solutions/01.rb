class Array
  def to_hash 
    self.flatten(1)  
    Hash[self]
  end
 
  def index_by
    indexed = {}
    self.each {|x| indexed[yield(x)] = x} #?? #ima li nujda ot self.each {...} ??
    indexed
  end
  
  def subarray_count(subarray)
    count = 0
    self.each_cons(subarray.length) {|x| count +=1 if x == subarray}
    count
  end    
      
  def occurences_count
    occurences = Hash.new(0)
    self.map {|x| occurences[x] += 1}
    occurences
  end
end