%w(Bayu
   vivi
   Effendi
   tri
   Devi
   Effendi
   Toni
   Heni
   Raditya
   Wira
   Yoga
   Popi
   Dimas
   Martin
   Pradipta
   Mahesa
   Unang
   Udin
   Anit).each_with_index do |name, index|
  Employee.create!(name: name, created_at: Time.now + index)
end
