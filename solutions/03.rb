require 'bigdecimal'
require 'bigdecimal/util' # добавя String#to_d

class GetOneFreePromotion
  attr_reader :number
  
  def initialize(number, price)
    @number, @price = number, price
  end  
  
  def promotion(amount)
    (amount/@number).floor * @price.to_s.to_d
  end
  
  def promotion_line(amount)
    l1 = sprintf("|   %-45s", "(buy " + (@number-1).to_s + ", get 1 free)")
    l1 += sprintf("|%9.2f |\n", -promotion(amount)) 
  end
end

class PackagePromotion
  attr_reader :number
  
  def initialize(info, price)
    @number, @percent = info.keys.first.to_s.to_d, info.values.first.to_s.to_d
    @price = price.to_s.to_d
  end  
  
  def promotion(amount)
    (amount/@number.to_i) * @number * @percent * "0.01".to_d * @price
  end
   
  def promotion_line(amount)
    percentage = "(get " + @percent.to_i.to_s + "% off for every " 
    l1 = sprintf("|   %-45s", percentage + @number.to_i.to_s + ")")
    l1 += sprintf("|%9.2f |\n", -promotion(amount)) 
  end
end

class ThresholdPromotion
  attr_reader :number
  
  def initialize(info, price)
    @number, @percent = info.keys.first, info.values.first
    @price = price
  end
  
  def promotion(amount)
    if amount <= @number
      0
    else  
      (amount-@number) * @price * @percent.to_s.to_d * "0.01".to_d
    end  
  end
  
  def promotion_line(amount)  
    percentage = "(" + @percent.to_s + "% off of every after the "
    l1 = sprintf("|   %-45s", percentage + @number.to_s + ending)
    l1 += sprintf("|%9.2f |\n", -promotion(amount)) 
  end
  
  private
  
  def ending
    case @number
      when 1 then "st)"
      when 2 then "nd)"
      when 3 then "rd)"
      else "th)"
    end 
  end
end

class Product
  attr_accessor :name, :price, :promotion
  
  def initialize(name, price, promotion = nil)
    @name, @price = name, price.to_d
    initializePromotion(promotion, @price) unless promotion.nil?
  end
  
  def discount(amount)
    @promotion.nil? ? 0 : (@promotion.promotion amount)
  end
  
  private
  
  def initializePromotion(promotion, price) 
    if promotion.keys.first == :get_one_free
      @promotion = GetOneFreePromotion.new(promotion.values.first, price)
    end
    if promotion.keys.first == :package
      @promotion = PackagePromotion.new(promotion.values.first, price)
    end  
    if promotion.keys.first == :threshold
      @promotion = ThresholdPromotion.new(promotion.values.first, price)
    end
  end
end

class PercentCoupon
  attr_accessor :name, :value
  
  def initialize(name, value)
    @name, @value = name, value.to_s.to_d
  end
  
  def discount(price)
    @value.to_s.to_d * "0.01".to_d * price.to_s.to_d
  end
  
  def price_off(price) 
    10 * price.to_s.to_d / (100-value.to_s.to_d)
  end
  
  def discount_line(worth)
    info = @name.to_s + " - " + sprintf("%d", @value) + "% off"
    sprintf("| Coupon %-40s", info) + sprintf("|%9.2f |\n", worth)
  end
end

class FixedCoupon
  attr_accessor :name, :value
  
  def initialize(name, value)
    @name, @value = name, value.to_s.to_d
  end
  
  def discount(price)
    (price > @value) ? @value : price
  end
  
  def price_off(price) 
    (price > @value) ? @value : price
  end
  
  def discount_line(worth)
    info = sprintf("| Coupon " + @name.to_s + " - %.2f off", @value.to_s)
    sprintf("%-49s", info) + sprintf("|%9.2f |\n", worth)
  end
end

class Cart
  attr_accessor :using_coupon

  def initialize(inventory, coupons)
    @cart = Hash.new(0)
    @inventory, @coupons, @using_coupon = inventory, coupons, nil
  end
  
  def add(product_name, number = 1)
    old_product = @inventory.select {|x| x.name == product_name}
    if old_product.empty? 
      raise "Invalid parameters passed."
    elsif number <= 0 or number > 99 
      raise "Invalid parameters passed."
    else
     @cart[old_product.first] += number 
    end
  end
  
  def use(coupon_name)
    @using_coupon = @coupons.select {|x| x.name == coupon_name}.first
  end
  
  def total()
    total = total1 - (@using_coupon.nil? ? 0 : @using_coupon.discount(total1))
  end
  
  def total1()
    prices = @cart.map {|product, amount| evalueate_price(product, amount)}
    t = prices.inject(:+)
    t = 0 unless t
    t
  end
  
  def invoice()
    line = '+' + '-' * 48 + '+' + '-' * 10 + '+' + "\n"
    t = line + '| Name' + ' ' * 39 + 'qty |' + ' ' * 4 + "price |\n" + line
    @cart.to_a.each {|product, amount| t += product_lines(product, amount)}
    t += @using_coupon.nil? ? '' : @using_coupon.discount_line(-total1+total)
    t += line + '| TOTAL' + ' ' * 42 + '|' + sprintf("%9.2f |\n", total) + line
  end 
  
  private
  
  def evalueate_price(product, amount)
    k = product.promotion.nil? ? 0 : product.promotion.promotion(amount)       
    product.price * amount - k
  end
  
  def product_lines(product, amount)
    t = sprintf("| %- 38s", product.name) + sprintf("%8d |", amount)
    t += sprintf("%9.2f |\n", amount * product.price)
    t += product.promotion.nil? ? '' : product.promotion.promotion_line(amount)
  end
end

class Inventory
  def initialize
    @inventory, @coupons = [], []
  end

  def register(product_name, price, promotion = nil)
    if product_name.length > 40 or 
      price.to_d < 0.01 or 
      price.to_d > 999.99 or 
      @inventory.include? product_name
        raise "Invalid parameters passed."
    else
      @inventory << Product.new(product_name, price, promotion)
    end
  end
  
  def register_coupon(name, details)
    if details.keys.first == :percent
      @coupons << PercentCoupon.new(name, details.values.first)
    elsif details.keys.first == :amount
      @coupons << FixedCoupon.new(name, details.values.first)
    end  
  end
  
  def new_cart
    Cart.new(@inventory, @coupons) 
  end
end