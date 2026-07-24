# frozen_string_literal: true
module TMASGateCounts
  Slice.register_provider(:tmas_locations) do
    start do
      register 'tmas_locations', {
        'ARCH0000' => 'Architecture',
        'ANXN0000' => 'Commons',
        'COTSEN' => 'Cotsen',
        'PLLR0000' => 'East Asian Library',
        'LEWIS' => 'Lewis and Engineering',
        'RHED0000' => 'Marquand',
        'MEND0000' => 'Mendel',
        'SLES0000' => 'Stokes Library'
      }.freeze
    end
  end
end
