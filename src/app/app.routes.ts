import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { RegistrationComponent } from './registration/registration.component';
import { MainpageComponent } from './mainpage/mainpage.component';
import { AboutuspageComponent } from './aboutuspage/aboutuspage.component';
import { ProductcardComponent } from './productcard/productcard.component';
import { ProfilepageComponent } from './profilepage/profilepage.component';
import { ProductpageComponent } from './productpage/productpage.component';
import { ProductimageComponent } from './productimage/productimage.component';

export const routes: Routes = [
  { path: 'login', component: LoginComponent },
  { path: 'registration', component: RegistrationComponent },
  { path: 'mainpage', component: MainpageComponent },
  { path: 'aboutuspage', component: AboutuspageComponent },
  { path: 'productcard', component: ProductcardComponent },
  { path: 'profile', component: ProfilepageComponent },
  { path: 'products', component: ProductpageComponent },
  { path: 'productimage/:id', component: ProductimageComponent }, // MÓDOSÍTVA: :id paraméterrel
  { path: '', redirectTo: 'login', pathMatch: 'full' }
];