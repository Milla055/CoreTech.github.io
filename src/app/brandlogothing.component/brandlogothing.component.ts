import { Component } from '@angular/core';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";

@Component({
  selector: 'app-brandlogothing.component',
  imports: [HeaderComponent, FooterComponent],
  templateUrl: './brandlogothing.component.html',
  styleUrl: './brandlogothing.component.css',
})
export class BrandlogothingComponent {

}
