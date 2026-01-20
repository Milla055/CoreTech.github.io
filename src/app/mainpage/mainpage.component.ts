import { Component } from '@angular/core';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { RouterLink } from "@angular/router";

@Component({
  selector: 'app-mainpage',
  imports: [HeaderComponent, FooterComponent, RouterLink],
  templateUrl: './mainpage.component.html',
  styleUrl: './mainpage.component.css',
})
export class MainpageComponent {

}
