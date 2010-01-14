
# TODO: Refactor all these to a helper, but not sure if prawn supports helpers like that


# def filter(text)
#   ic = Iconv.new('ISO-8859-15//IGNORE//TRANSLIT','utf-8')
#   ic.iconv(text)
# end


# TODO: remove filter
def user_address
  address = "#{@contract.user.name}"
  address += "\n#{@contract.user.address}" unless @contract.user.address.blank?
  address += "\n" unless @contract.user.zip.blank? and @contract.user.city.blank?
  address += "#{@contract.user.zip} " unless @contract.user.zip.blank?
  address += "#{@contract.user.city}" unless @contract.user.city.blank?
  address += "\n #{@contract.user.country}" unless @contract.user.country.blank?
  address += "\n #{@contract.user.email}" unless @contract.user.email.blank?
  address += "\n #{@contract.user.phone}" unless @contract.user.phone.blank?
  address += "\n #{_("Badge ID:")} #{@contract.user.badge_id}" unless @contract.user.badge_id.blank?
  return address
end

def lending_address
  # Print something like: AV-Ausleihe (AVZ)
  address = @contract.inventory_pool.name unless @contract.inventory_pool.name.blank?
  address += " (#{@contract.inventory_pool.shortname})"
  address += "\n" + CONTRACT_LENDING_PARTY_STRING
end

if @contract.purpose.nil?
  purpose = _("No purpose given.")
else
  purpose = @contract.purpose
end


pdf.font("Helvetica")
pdf.font_size(10)

pdf.font_size(14) do
  pdf.text _("Contract no. %d") % @contract.id
end

pdf.move_down 3.mm

pdf.text(filter(_("This lending contract covers borrowing the following items by the person (natural or legal) described as 'borrowing party' below. Use of these items is only allowed for the purpose given below.")) )


borrowing_party = _("Borrowing party:") + "\n" + user_address
lending_party = _("Lending party:") + "\n" + lending_address

pdf.text_box borrowing_party, 
             :width => 150,
             :height => pdf.height_of(borrowing_party),
             :overflow => :ellipses,
             :at => [pdf.bounds.left, pdf.bounds.top - 55]

pdf.text_box lending_party,
             :width => 150,
             :height => pdf.height_of(lending_party),
             :overflow => :ellipses,
             :at => [pdf.bounds.left + 70.mm, pdf.bounds.top - 55]


pdf.move_down [pdf.height_of(borrowing_party), pdf.height_of(lending_party)].max + 10.mm


table_headers = [_("Qt"), _("Inventory Code"), _("Model"),  _("Start date"), _("End date"), _("Returned date")]


total_value = 0
mindate = @contract.lines[0].end_date

table_data = []

@contract.lines.each do |l|
   
   mindate = l.end_date if ( l.end_date < mindate && l.returned_date.nil? )

   table_data << [ l.quantity, 
                   l.item.inventory_code,
                   l.model.name, 
                   short_date(l.start_date),
                   short_date(l.end_date),
                   short_date(l.returned_date) ]
  
end

# Print the lowest item return time somewhere in a corner, just as reference
# for inventory managers
pdf.font_size(9) do
  pdf.text_box(short_date(mindate),
              :width => 20.mm,
              :height => 15.mm,
              :overflow => :ellipses,
              :at => [pdf.bounds.top_right[0] - 12.mm, pdf.bounds.top_right[1] ])
              #:at => [pdf.bounds.top - 20.mm, pdf.bounds.right + 25.mm])
end

pdf.table(table_data, 
          :column_widths  => { 0 => 10.mm, 1 => 25.mm, 2 => 70.mm, 3 => 22.mm, 4 => 22.mm, 5 => 28.mm},
          :align          => { 0 => :right, 1 => :left, 2 => :left, 3 => :left, 4 => :left, 5 => :left },
          :headers        => table_headers,
          :font_size      => 9,
          :padding        => 3,
          :row_colors     => ['ffffff','f1f1f1'])

pdf.move_down 6.mm

pdf.text "#{_("Purpose:")} #{purpose}"
pdf.move_down 3.mm

pdf.text "#{_("Additional notes:")} #{@contract.note}"
pdf.move_down 3.mm

pdf.font_size(7) do 
  
  pdf.text "Die Benutzerin/der Benutzer ist bei unsachgemässer Handhabung oder Verlust schadenersatzpflichtig. Sie/Er verpflichtet sich, das Material sorgfältig zu behandeln und gereinigt zu retournieren. Bei mangelbehafteter oder verspäteter Rückgabe kann eine Ausleihsperre (bis zu 6 Monaten) verhängt werden. Das geliehene Material bleibt jederzeit uneingeschränktes Eigentum der Zürcher Hochschule der Künste und darf ausschliesslich für schulische Zwecke eingesetzt werden. Mit ihrer/seiner Unterschrift akzeptiert die Benutzerin/der Benutzer diese Bedingungen sowie die 'Richtlinie zur Ausleihe von Sachen' der ZHdK und etwaige abteilungsspezifische Ausleih-Richtlinien."
  
end


today = Date.today.strftime("%d.%m.%Y")

pdf.move_down 8.mm

pdf.text "#{_("Signature of borrower:")} #{today}," 

pdf.stroke do
  pdf.line_width 0.5
  pdf.horizontal_line pdf.bounds.left, 160.mm
end

pdf.move_down 8.mm

pdf.text "#{_("Signature of person taking back the item:")}" 

pdf.stroke do
  pdf.line_width 0.5
  pdf.horizontal_line pdf.bounds.left, 160.mm
end