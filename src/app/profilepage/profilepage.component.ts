import { Component } from '@angular/core';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { User, UserService } from '../services/profile.service';
import { HeaderComponent } from "../header/header.component";
import { FooterComponent } from "../footer/footer.component";

@Component({
  selector: 'app-profilepage',
  imports: [HeaderComponent, FooterComponent],
  templateUrl: './profilepage.component.html',
  styleUrl: './profilepage.component.css',
})
export class ProfilepageComponent {
    activeTab: string = 'kijelentkezes';
  
  customerDataForm!: FormGroup;
  passwordForm!: FormGroup;
  deliveryDataForm!: FormGroup;

  // This will hold the current user's data
  userData: any = null;

  constructor(
    private fb: FormBuilder
    // private userService: UserService  // Inject your user service here
  ) {}

  ngOnInit(): void {
    this.loadUserData();
    this.initializeForms();
  }

  loadUserData(): void {
    // TODO: Replace this with actual API call to get logged-in user data
    // Example: this.userService.getCurrentUser().subscribe(user => { this.userData = user; });
    
    // For now, this simulates getting user data from localStorage or a service
    const storedUser = localStorage.getItem('currentUser');
    if (storedUser) {
      this.userData = JSON.parse(storedUser);
    } else {
      // Default/fallback data if no user is logged in
      this.userData = {
        email: 'bajor.mark@szechenyi.hu',
        telefonszam: '',
        role: 'Admin'
      };
    }
  }

  initializeForms(): void {
    // Vásárlói Adatok Form - populated with current user data
    this.customerDataForm = this.fb.group({
      email: [this.userData?.email || '', [Validators.required, Validators.email]],
      vezetekNev: [this.userData?.vezetekNev || '', Validators.required],
      keresztNev: [this.userData?.keresztNev || '', Validators.required]
    });

    // Jelszó Form
    this.passwordForm = this.fb.group({
      regiJelszo: ['', Validators.required],
      ujJelszo: ['', [Validators.required, Validators.minLength(6)]],
      ujJelszoMegerosites: ['', Validators.required]
    });

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

  getFullName(): string {
    return `${this.userData?.vezetekNev || ''} ${this.userData?.keresztNev || ''}`;
  }

  getFullAddress(): string {
    if (!this.userData?.cim) return '';
    const { varos, iranyitoszam, utcaHazszam } = this.userData.cim;
    return `${varos}, ${iranyitoszam}, ${utcaHazszam}`;
  }

  setActiveTab(tab: string): void {
    this.activeTab = tab;
  }

  onSubmit(): void {
    if (this.customerDataForm.valid && this.deliveryDataForm.valid) {
      const updatedData = {
        email: this.customerDataForm.value.email,
        
        telefonszam: this.deliveryDataForm.value.telefonszam
      };

      // TODO: Call your API to update user data
      // this.userService.updateUser(updatedData).subscribe(response => {
      //   console.log('User updated successfully');
      //   this.userData = { ...this.userData, ...updatedData };
      //   localStorage.setItem('currentUser', JSON.stringify(this.userData));
      // });

      console.log('Updated Data:', updatedData);
      
      // For now, update localStorage
      this.userData = { ...this.userData, ...updatedData };
      localStorage.setItem('currentUser', JSON.stringify(this.userData));
      
      alert('Változások sikeresen mentve!');
    }
  }

  resetChanges(): void {
    // Reset forms to original user data
    this.customerDataForm.patchValue({
      email: this.userData?.email || '',
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
}
