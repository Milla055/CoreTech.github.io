import { Component, EventEmitter, Output } from '@angular/core';
import { Router } from '@angular/router';

@Component({
  selector: 'app-shopmenu',
  imports: [],
  templateUrl: './shopmenu.component.html',
  styleUrl: './shopmenu.component.css',
})
export class ShopmenuComponent {
  @Output() close = new EventEmitter<void>();

  constructor(private router: Router) {}

  

  // Navigate to products page with category filter
  navigateToCategory(categoryName: string, categoryId: number) {
    this.router.navigate(['/products'], {
      queryParams: {
        category: categoryId,
        search: categoryName
      }
    });
    
  }

  // Category navigation methods
  onVideokartya() { this.navigateToCategory('Videókártya', 1); }
  onProcesszor() { this.navigateToCategory('Processzor', 2); }
  onMemoria() { this.navigateToCategory('Memória (RAM)', 4); }
  onAlaplap() { this.navigateToCategory('Alaplap', 3); }
  onSSD() { this.navigateToCategory('SSD', 6); }
  onHDD() { this.navigateToCategory('HDD', 7); }
  onHutes() { this.navigateToCategory('Hűtés', 9); }
  onTapegyseg() { this.navigateToCategory('Tápegység', 5); }
  onGephaz() { this.navigateToCategory('Gépház', 8); }
  onEger() { this.navigateToCategory('Egér', 11); }
  onBillentyuzet() { this.navigateToCategory('Billentyűzet', 12); }
  onEgerpad() { this.navigateToCategory('Egérpad', 15); }
  onMonitor() { this.navigateToCategory('Monitor', 13); }
  onMikrofon() { this.navigateToCategory('Mikrofon', 16); }
  onFejhallgato() { this.navigateToCategory('Fejhallgató', 14); }
}