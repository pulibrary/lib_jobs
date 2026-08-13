# frozen_string_literal: true
module TMASGateCounts
  Slice.register_provider(:tmas_locations) do
    start do
      register 'tmas_locations', {
        'ARCH0000' => 'Architecture',
        'ANXN0000' => 'Commons',
        'COTSEN' => 'Cotsen',
        'ENG0000' => 'Engineering',
        'MAKER000' => 'Makerspace',
        'PLLR0000' => 'East Asian Library',
        'LEWIS' => 'Lewis',
        'RHED0000' => 'Marquand',
        'MEND0000' => 'Mendel',
        'SLES0000' => 'Stokes Library'
      }.freeze
    end
  end
end
