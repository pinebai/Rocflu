!*********************************************************************
!* Illinois Open Source License                                      *
!*                                                                   *
!* University of Illinois/NCSA                                       * 
!* Open Source License                                               *
!*                                                                   *
!* Copyright@2008, University of Illinois.  All rights reserved.     *
!*                                                                   *
!*  Developed by:                                                    *
!*                                                                   *
!*     Center for Simulation of Advanced Rockets                     *
!*                                                                   *
!*     University of Illinois                                        *
!*                                                                   *
!*     www.csar.uiuc.edu                                             *
!*                                                                   *
!* Permission is hereby granted, free of charge, to any person       *
!* obtaining a copy of this software and associated documentation    *
!* files (the "Software"), to deal with the Software without         *
!* restriction, including without limitation the rights to use,      *
!* copy, modify, merge, publish, distribute, sublicense, and/or      *
!* sell copies of the Software, and to permit persons to whom the    *
!* Software is furnished to do so, subject to the following          *
!* conditions:                                                       *
!*                                                                   *
!*                                                                   *
!* @ Redistributions of source code must retain the above copyright  * 
!*   notice, this list of conditions and the following disclaimers.  *
!*                                                                   * 
!* @ Redistributions in binary form must reproduce the above         *
!*   copyright notice, this list of conditions and the following     *
!*   disclaimers in the documentation and/or other materials         *
!*   provided with the distribution.                                 *
!*                                                                   *
!* @ Neither the names of the Center for Simulation of Advanced      *
!*   Rockets, the University of Illinois, nor the names of its       *
!*   contributors may be used to endorse or promote products derived * 
!*   from this Software without specific prior written permission.   *
!*                                                                   *
!* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,   *
!* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES   *
!* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND          *
!* NONINFRINGEMENT.  IN NO EVENT SHALL THE CONTRIBUTORS OR           *
!* COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       * 
!* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   *
!* ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE    *
!* USE OR OTHER DEALINGS WITH THE SOFTWARE.                          *
!*********************************************************************
!* Please acknowledge The University of Illinois Center for          *
!* Simulation of Advanced Rockets in works and publications          *
!* resulting from this software or its derivatives.                  *
!*********************************************************************
! ******************************************************************************
!
! Purpose: Compute integrals for GENx checking.
!
! Description: None.
!
! Input:
!   regions     Region data
!
! Output:
!   integ       Vector of integrals (for output by Rocman)
!
! Notes: None.
!
! ******************************************************************************
!
! $Id: RFLU_ComputeIntegralValues.F90,v 1.1.1.1 2015/01/23 22:57:50 tbanerjee Exp $
!
! Copyright: (c) 2002-2005 by the University of Illinois
!
! ******************************************************************************

#ifdef GENX
SUBROUTINE RFLU_ComputeIntegralValues(regions,integ)
#else
SUBROUTINE RFLU_ComputeIntegralValues(regions)
#endif

  USE ModGlobal, ONLY: t_global
  USE ModParameters
  USE ModDataTypes
  USE ModBndPatch, ONLY: t_patch
  USE ModDataStruct, ONLY: t_region
  USE ModError
  USE ModMPI
  
  IMPLICIT NONE

#ifdef GENX
  INCLUDE 'rocmanf90.h'
#endif

! ******************************************************************************
! Declarations and definitions
! ******************************************************************************

! ==============================================================================
! Arguments
! ==============================================================================

  TYPE(t_region), POINTER :: regions(:)

! ==============================================================================
! Locals
! ==============================================================================

  CHARACTER(CHRLEN) :: RCSIdentString
  INTEGER :: errorFlag,i,ic,ifc,iPatch,iReg
  REAL(RFREAL) :: enerLocal,ibAreaLocal,inbAreaLocal,massLocal,xMomLocal, & 
                  yMomLocal,zMomLocal,volLocal
#ifdef GENX
  DOUBLE PRECISION, DIMENSION(MAN_INTEG_SIZE) :: integ
  REAL(RFREAL), DIMENSION(MAN_INTEG_SIZE) :: globalVals,localVals
#else
  REAL(RFREAL), DIMENSION(2) :: globalVals,localVals
#endif
  REAL(RFREAL), DIMENSION(:), POINTER :: pVol
  REAL(RFREAL), DIMENSION(:,:), POINTER :: pCv
  TYPE(t_global), POINTER :: global
  TYPE(t_patch), POINTER :: pPatch  
  TYPE(t_region), POINTER :: pRegion

! ******************************************************************************
! Start 
! ******************************************************************************

  RCSIdentString = '$RCSfile: RFLU_ComputeIntegralValues.F90,v $ $Revision: 1.1.1.1 $'

  global => regions(1)%global

  CALL RegisterFunction(global,'RFLU_ComputeIntegralValues',__FILE__)

! ******************************************************************************
! Compute total volume and total mass
! ******************************************************************************

  volLocal  = 0.0_RFREAL
  massLocal = 0.0_RFREAL

  DO iReg = 1,global%nRegionsLocal
    pRegion => regions(iReg)
    
    pVol => pRegion%grid%vol
    pCv  => pRegion%mixt%cv
    
    DO ic = 1,pRegion%grid%nCells
      volLocal  = volLocal  + pVol(ic)
      massLocal = massLocal + pCv(CV_MIXT_DENS,ic)*pVol(ic)
    END DO ! ic
  END DO ! iReg

#ifdef GENX
! ******************************************************************************
! Compute momenta components and energy
! ******************************************************************************

  xMomLocal = 0.0_RFREAL ! Not computed at present
  yMomLocal = 0.0_RFREAL
  zMomLocal = 0.0_RFREAL
  enerLocal = 0.0_RFREAL 

! ******************************************************************************
! Compute interacting surface areas
! ******************************************************************************

  inbAreaLocal = 0.0_RFREAL
  ibAreaLocal  = 0.0_RFREAL

  DO iReg = 1,global%nRegionsLocal 
    pRegion => regions(iReg)  
  
    DO iPatch = 1,pRegion%grid%nPatches
      pPatch => pRegion%patches(iPatch)
    
      IF ( pPatch%bcCoupled == BC_BURNING ) THEN  
        DO ifc = 1,pPatch%nBFaces
          ibAreaLocal = ibAreaLocal + pPatch%fn(XYZMAG,ifc)
        END DO ! ifc  
      ELSE IF ( pPatch%bcCoupled == BC_NOT_BURNING ) THEN
        DO ifc = 1,pPatch%nBFaces
          inbAreaLocal = inbAreaLocal + pPatch%fn(XYZMAG,ifc)
        END DO ! ifc   
      END IF ! pPatach%bcCoupled
    END DO ! iPatch
  END DO ! iReg
#endif 

! ******************************************************************************
! Gather data
! ******************************************************************************

#ifdef GENX
  localVals(MAN_INTEG_VOL    ) = volLocal
  localVals(MAN_INTEG_MASS   ) = massLocal
  localVals(MAN_INTEG_XMOM   ) = xMomLocal
  localVals(MAN_INTEG_YMOM   ) = yMomLocal
  localVals(MAN_INTEG_ZMOM   ) = zMomLocal
  localVals(MAN_INTEG_ENER   ) = enerLocal
  localVals(MAN_INTEG_IBAREA ) = ibAreaLocal  
  localVals(MAN_INTEG_INBAREA) = inbAreaLocal      
#else
  localVals(1) = volLocal
  localVals(2) = massLocal  
#endif

! ******************************************************************************
! Perform reduction operation
! ******************************************************************************

  CALL MPI_Reduce(localVals,globalVals,SIZE(localVals,1),MPI_RFREAL,MPI_SUM, &
                  MASTERPROC,global%mpiComm,errorFlag)
  global%error = errorFlag
  IF ( global%error /= ERR_NONE ) THEN 
    CALL ErrorStop(global,ERR_MPI_TROUBLE,__LINE__)
  END IF ! global%errorFlag
 
! ******************************************************************************
! Scatter data
! ******************************************************************************

#ifdef GENX
  DO i = 1,MAN_INTEG_SIZE ! Explicit loop to avoid ASCI White problem
    integ(i) = globalVals(i)
  END DO ! i
#else
  global%totalVol  = globalVals(1)
  global%totalMass = globalVals(2)  
#endif

! ******************************************************************************
! End
! ******************************************************************************

  CALL DeregisterFunction(global)

END SUBROUTINE RFLU_ComputeIntegralValues

!* *****************************************************************************
!
! RCS Revision history:
!
! $Log: RFLU_ComputeIntegralValues.F90,v $
! Revision 1.1.1.1  2015/01/23 22:57:50  tbanerjee
! merged rocflu micro and macro
!
! Revision 1.1.1.1  2014/07/15 14:31:38  brollin
! New Stable version
!
! Revision 1.3  2008/12/06 08:43:47  mtcampbe
! Updated license.
!
! Revision 1.2  2008/11/19 22:17:00  mtcampbe
! Added Illinois Open Source License/Copyright
!
! Revision 1.1  2007/04/09 18:49:57  haselbac
! Initial revision after split from RocfloMP
!
! Revision 1.1  2007/04/09 18:01:01  haselbac
! Initial revision after split from RocfloMP
!
! Revision 1.5  2006/04/07 15:19:22  haselbac
! Removed tabs
!
! Revision 1.4  2005/04/15 15:07:14  haselbac
! Converted to MPI, cosmetics
!
! Revision 1.3  2003/04/23 13:58:56  haselbac
! Bug fix
!
! Revision 1.2  2003/01/28 14:32:16  haselbac
! Use parameters in fn
!
! Revision 1.1  2002/11/15 21:27:46  haselbac
! Initial revision
!
! ******************************************************************************

