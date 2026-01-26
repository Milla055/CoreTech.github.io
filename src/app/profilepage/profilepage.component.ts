import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { User, UserService } from '../services/profile.service';
import { AuthService } from '../services/auth.service';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-profilepage',
  standalone: true,
  imports: [HeaderComponent, FooterComponent, ReactiveFormsModule, CommonModule],
  templateUrl: './profilepage.component.html',
  styleUrl: './profilepage.component.css',
})
export class ProfilepageComponent {
  activeTab: string = 'fiokkezeles';
  
  customerDataForm!: FormGroup;
  passwordForm!: FormGroup;
  deliveryDataForm!: FormGroup;

  // This will hold the current user's data
  userData: any = null;

  constructor(
    private fb: FormBuilder,
    private router: Router,
    private authService: AuthService
    // private userService: UserService  // Inject your user service here
  ) {}

  ngOnInit(): void {
    this.loadUserData();
  }

  loadUserData(): void {
    // Get the logged-in user's data from AuthService
    const currentUser = this.authService.getCurrentUser();
    
    if (currentUser) {
      // User is logged in, use their data directly from localStorage
      this.userData = {
        email: currentUser.email,
        username: currentUser.username,
        role: currentUser.role, // Use exact role from backend (no fallback)
        telefonszam: '',
        vezetekNev: '',
        keresztNev: '',
        cim: {}
      };
      
      localStorage.setItem('currentUser', JSON.stringify(this.userData));
      this.initializeForms();
    } else {
      // No user logged in, redirect to login
      this.router.navigate(['/login']);
    }
  }

  initializeForms(): void {
    // Vásárlói Adatok Form - populated with current user data (email field empty)
    this.customerDataForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      vezetekNev: [this.userData?.vezetekNev || '', Validators.required],
      keresztNev: [this.userData?.keresztNev || '', Validators.required]
    });

    // Jelszó Form with custom validator for password confirmation
    this.passwordForm = this.fb.group({
      regiJelszo: ['', Validators.required],
      ujJelszo: ['', [Validators.required, Validators.minLength(6)]],
      ujJelszoMegerosites: ['', Validators.required]
    }, { validators: this.passwordMatchValidator });

    // Szállítási Adatok Form - populated with current user address
    this.deliveryDataForm = this.fb.group({
      orszag: [this.userData?.cim?.orszag || '', Validators.required],
      iranyitoszam: [this.userData?.cim?.iranyitoszam || '', Validators.required],
      varos: [this.userData?.cim?.varos || '', Validators.required],
      utcaHazszam: [this.userData?.cim?.utcaHazszam || '', Validators.required],
      email: [this.userData?.email || '', [Validators.required, Validators.email]],
      telefonszam: [this.userData?.telefonszam || '', Validators.required]
    });
  }

  // Custom validator to check if passwords match
  passwordMatchValidator(group: FormGroup): { [key: string]: boolean } | null {
    const newPassword = group.get('ujJelszo')?.value;
    const confirmPassword = group.get('ujJelszoMegerosites')?.value;
    
    if (newPassword !== confirmPassword) {
      return { passwordMismatch: true };
    }
    return null;
  }

  getFullName(): string {
    return `${this.userData?.vezetekNev || ''} ${this.userData?.keresztNev || ''}`.trim() || this.userData?.username || 'User';
  }

  getFullAddress(): string {
    if (!this.userData?.cim) return '';
    const { varos, iranyitoszam, utcaHazszam } = this.userData.cim;
    return `${varos}, ${iranyitoszam}, ${utcaHazszam}`;
  }

  setActiveTab(tab: string): void {
    this.activeTab = tab;
  }

  isAdmin(): boolean {
    return this.userData?.role === 'Admin';
  }

  onSubmit(): void {
    if (this.customerDataForm.valid && this.deliveryDataForm.valid) {
      const updatedData = {
        email: this.customerDataForm.value.email,
        vezetekNev: this.customerDataForm.value.vezetekNev,
        keresztNev: this.customerDataForm.value.keresztNev,
        telefonszam: this.deliveryDataForm.value.telefonszam,
        cim: {
          orszag: this.deliveryDataForm.value.orszag,
          iranyitoszam: this.deliveryDataForm.value.iranyitoszam,
          varos: this.deliveryDataForm.value.varos,
          utcaHazszam: this.deliveryDataForm.value.utcaHazszam
        }
      };

       /* TODO: Call your API to update user data
       this.userService.updateUser(updatedData).subscribe(
         response => {
           console.log('User updated successfully');
           this.userData = { ...this.userData, ...updatedData };
           localStorage.setItem('currentUser', JSON.stringify(this.userData));
           alert('Változások sikeresen mentve!');
         },
         error => {
           console.error('Error updating user:', error);
           alert('Hiba történt a mentés során!');
         }
       );
 */
      console.log('Updated Data:', updatedData);
      
      // For now, update localStorage
      this.userData = { ...this.userData, ...updatedData };
      localStorage.setItem('currentUser', JSON.stringify(this.userData));
      
      alert('Változások sikeresen mentve!');
    } else {
      alert('Kérlek töltsd ki az összes kötelező mezőt helyesen!');
    }
  }

  // Method to change password
  onPasswordChange(): void {
    if (this.passwordForm.valid) {
      const oldPassword = this.passwordForm.value.regiJelszo;
      const newPassword = this.passwordForm.value.ujJelszo;
      const confirmPassword = this.passwordForm.value.ujJelszoMegerosites;

      // Check if new passwords match
      if (newPassword !== confirmPassword) {
        alert('Az új jelszavak nem egyeznek!');
        return;
      }

      // Call the AuthService to change password
      this.authService.changePassword(oldPassword, newPassword).subscribe(
        response => {
          console.log('Password changed successfully', response);
          alert('Jelszó sikeresen megváltoztatva!');
          this.passwordForm.reset();
        },
        error => {
          console.error('Error changing password:', error);
          if (error.status === 401) {
            alert('A régi jelszó helytelen!');
          } else if (error.status === 400) {
            alert('Érvénytelen jelszó formátum!');
          } else {
            alert('Hiba történt a jelszó változtatása során!');
          }
        }
      );
    } else {
      alert('Kérlek töltsd ki az összes jelszó mezőt helyesen!');
    }
  }

  resetChanges(): void {
    // Reset forms to original user data
    this.customerDataForm.patchValue({
      email: '',
      vezetekNev: this.userData?.vezetekNev || '',
      keresztNev: this.userData?.keresztNev || ''
    });

    this.passwordForm.reset();

    this.deliveryDataForm.patchValue({
      orszag: this.userData?.cim?.orszag || '',
      iranyitoszam: this.userData?.cim?.iranyitoszam || '',
      varos: this.userData?.cim?.varos || '',
      utcaHazszam: this.userData?.cim?.utcaHazszam || '',
      email: this.userData?.email || '',
      telefonszam: this.userData?.telefonszam || ''
    });
  }

  // Logout method
  logout(): void {
    // Call the logout method from AuthService
    this.authService.logout();
    
    // Navigate to the main page (or login page)
    this.router.navigate(['/mainpage']);
  }
}