# WaveformViewer

Waveform data represents important information and can provide valuable insights about the patient health, for example about cardiac dysfunction that can be induced by sepsis. However, only a few studies have utilized waveform data when developing machine learning models for ICU-relevant applications.
Our project partner is working on extracting raw waveform data from bed-side monitors in the ICU. To support the involved clinicians in validating the data quality, we are developing a graphical interface in MATLAB to display the recorded signals.

The main functionalities are: 
1. Display different channels of ECG, SpO2, and blood pressure curves aligned over time
2. Slide through time by changing the position and length of the displayed window
3. Slider to scale the y-axis for the signals separately
4. De-/select curves and groups of curves to display
5. Scale the background grid based on ECG paper speed.

Screenshot:
![Viewer Screenshot](Viewer-Screenshot_25-01-24.png?raw=true "Viewer Screenshot")

---
The code uses the implementation of the Pan-Tompkins QRS-detector from https://de.mathworks.com/matlabcentral/fileexchange/45840-complete-pan-tompkins-implementation-ecg-qrs-detector
> H. Sedghamiz, "Matlab Implementation of Pan Tompkins ECG QRS detector.", March 2014. https://www.researchgate.net/publication/313673153_Matlab_Implementation_of_Pan_Tompkins_ECG_QRS_detect
<br> <br>
J. Pan.J, W.J. Tompkins. ,"A Real-Time QRS Detection Algorithm" IEEE Transactions on Biomedical Engineering, vol. BME-32, No. 3, 1985. 
