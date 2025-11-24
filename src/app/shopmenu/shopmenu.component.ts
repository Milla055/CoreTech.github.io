import { Component, EventEmitter, Output } from '@angular/core';


@Component({
  selector: 'app-shopmenu',
  imports: [],
  templateUrl: './shopmenu.component.html',
  styleUrl: './shopmenu.component.css',
})
export class ShopmenuComponent {
  @Output() close = new EventEmitter<void>();

  closeShopMenu() {
    this.close.emit();
  }
}
