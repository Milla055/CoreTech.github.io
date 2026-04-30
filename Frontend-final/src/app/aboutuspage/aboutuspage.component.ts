import { Component } from '@angular/core';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";

@Component({
  selector: 'app-aboutuspage',
  imports: [HeaderComponent, FooterComponent],
  templateUrl: './aboutuspage.component.html',
  styleUrl: './aboutuspage.component.css',
})
export class AboutuspageComponent {

}
